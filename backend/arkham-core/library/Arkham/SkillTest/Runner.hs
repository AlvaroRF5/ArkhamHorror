{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.SkillTest.Runner (module X) where

import Arkham.Prelude

import Arkham.SkillTest as X

import Arkham.Action (Action)
import Arkham.SkillTestResult
import Arkham.SkillType
import Arkham.Card
import Arkham.Classes
import Arkham.Game.Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id
import Arkham.Location.Attrs
import Arkham.Helpers.Investigator
import Arkham.Message
import Arkham.Modifier
import Arkham.Projection
import Arkham.RequestedTokenStrategy
import Arkham.Source
import Arkham.Stats
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Token
import Arkham.Window (Window(..))
import Arkham.Window qualified as Window
import Data.HashMap.Strict qualified as HashMap
import Data.Semigroup

skillIconCount :: SkillTest -> GameT Int
skillIconCount st@SkillTest {..} = do
  investigatorModifiers <-
    getModifiers
      (toSource st)
      (InvestigatorTarget skillTestInvestigator)
  if SkillCannotBeIncreased skillTestSkillType `elem` investigatorModifiers
    then pure 0
    else
      length . filter matches
        <$> concatMapM
          (iconsForCard . snd)
          (toList skillTestCommittedCards)
 where
  iconsForCard c@(PlayerCard MkPlayerCard {..}) = do
    modifiers' <- getModifiers (toSource st) (CardIdTarget pcId)
    pure $ foldr applySkillModifiers (cdSkills $ toCardDef c) modifiers'
  iconsForCard _ = pure []
  matches SkillWild = True
  matches s = s == skillTestSkillType
  applySkillModifiers (AddSkillIcons xs) ys = xs <> ys
  applySkillModifiers _ ys = ys

getModifiedSkillTestDifficulty :: SkillTest -> GameT Int
getModifiedSkillTestDifficulty s = do
  modifiers' <- getModifiers (toSource s) SkillTestTarget
  let preModifiedDifficulty =
        foldr applyPreModifier (skillTestDifficulty s) modifiers'
  pure $ foldr applyModifier preModifiedDifficulty modifiers'
 where
  applyModifier (Difficulty m) n = max 0 (n + m)
  applyModifier DoubleDifficulty n = n * 2
  applyModifier _ n = n
  applyPreModifier (SetDifficulty m) _ = m
  applyPreModifier _ n = n

-- per the FAQ the double negative modifier ceases to be active
-- when Sure Gamble is used so we overwrite both Negative and DoubleNegative
getModifiedTokenValue ::
  SkillTest ->
  Token ->
  GameT Int
getModifiedTokenValue s t = do
  tokenModifiers' <- getModifiers (toSource s) (TokenTarget t)
  modifiedTokenFaces' <- getModifiedTokenFaces s [t]
  getSum . mconcat
    <$> for
      modifiedTokenFaces'
      ( \tokenFace -> do
          baseTokenValue <- getTokenValue (skillTestInvestigator s) tokenFace ()
          let updatedTokenValue =
                tokenValue $ foldr applyModifier baseTokenValue tokenModifiers'
          pure . Sum $ fromMaybe 0 updatedTokenValue
      )
 where
  applyModifier IgnoreToken (TokenValue token _) = TokenValue token NoModifier
  applyModifier (ChangeTokenModifier modifier') (TokenValue token _) =
    TokenValue token modifier'
  applyModifier NegativeToPositive (TokenValue token (NegativeModifier n)) =
    TokenValue token (PositiveModifier n)
  applyModifier NegativeToPositive (TokenValue token (DoubleNegativeModifier n)) =
    TokenValue token (PositiveModifier n)
  applyModifier DoubleNegativeModifiersOnTokens (TokenValue token (NegativeModifier n)) =
    TokenValue token (DoubleNegativeModifier n)
  applyModifier (TokenValueModifier m) (TokenValue token (PositiveModifier n)) =
    TokenValue token (PositiveModifier (max 0 (n + m)))
  applyModifier (TokenValueModifier m) (TokenValue token (NegativeModifier n)) =
    TokenValue token (NegativeModifier (max 0 (n - m)))
  applyModifier _ currentTokenValue = currentTokenValue

instance RunMessage SkillTest where
  runMessage msg s@SkillTest {..} = case msg of
    TriggerSkillTest iid -> do
      modifiers' <- getModifiers (toSource s) (InvestigatorTarget iid)
      if DoNotDrawChaosTokensForSkillChecks `elem` modifiers'
        then s <$ push (RunSkillTest iid)
        else
          s
            <$ pushAll
              [RequestTokens (toSource s) (Just iid) 1 SetAside, RunSkillTest iid]
    DrawAnotherToken iid -> do
      withQueue_ $
        filter $ \case
          Will FailedSkillTest {} -> False
          Will PassedSkillTest {} -> False
          CheckWindow _ [Window Timing.When (Window.WouldFailSkillTest _)] ->
            False
          CheckWindow _ [Window Timing.When (Window.WouldPassSkillTest _)] ->
            False
          RunWindow _ [Window Timing.When (Window.WouldPassSkillTest _)] ->
            False
          RunWindow _ [Window Timing.When (Window.WouldFailSkillTest _)] ->
            False
          Ask skillTestInvestigator' (ChooseOne [SkillTestApplyResults])
            | skillTestInvestigator == skillTestInvestigator' -> False
          _ -> True
      pushAll
        [RequestTokens (toSource s) (Just iid) 1 SetAside, RunSkillTest iid]
      pure $ s & (resolvedTokensL %~ (<> skillTestRevealedTokens))
    RequestedTokens (SkillTestSource siid skillType source maction) (Just iid) tokenFaces ->
      do
        push (RevealSkillTestTokens iid)
        for_ tokenFaces $ \tokenFace -> do
          pushAll $
            resolve
              ( RevealToken
                  (SkillTestSource siid skillType source maction)
                  iid
                  tokenFace
              )
        pure $ s & (setAsideTokensL %~ (tokenFaces <>))
    RevealToken SkillTestSource {} iid token -> do
      push
        (CheckWindow [iid] [Window Timing.After (Window.RevealToken iid token)])
      pure $ s & revealedTokensL %~ (token :)
    RevealSkillTestTokens iid -> do
      revealedTokenFaces <- flip
        concatMapM
        (skillTestRevealedTokens \\ skillTestResolvedTokens)
        \token -> do
          faces <- getModifiedTokenFaces s [token]
          pure [(token, face) | face <- faces]
      pushAll
        [ ResolveToken drawnToken tokenFace iid
        | (drawnToken, tokenFace) <- revealedTokenFaces
        ]
      pure $
        s
          & ( subscribersL
                %~ (<> [TokenTarget token' | token' <- skillTestRevealedTokens])
            )
    PassSkillTest -> do
      stats <- modifiedStatsOf (toSource s) skillTestAction skillTestInvestigator
      iconCount <- skillIconCount s
      let currentSkillValue = statsSkillValue stats skillTestSkillType
          modifiedSkillValue' =
            max 0 (currentSkillValue + skillTestValueModifier + iconCount)
      pushAll
        [ chooseOne skillTestInvestigator [SkillTestApplyResults]
        , SkillTestEnds skillTestSource
        ]
      pure $ s & resultL .~ SucceededBy True modifiedSkillValue'
    FailSkillTest -> do
      difficulty <- getModifiedSkillTestDifficulty s
      pushAll $
        [ Will
          ( FailedSkillTest
              skillTestInvestigator
              skillTestAction
              skillTestSource
              target
              skillTestSkillType
              difficulty
          )
        | target <- skillTestSubscribers
        ]
          <> [ Will
                ( FailedSkillTest
                    skillTestInvestigator
                    skillTestAction
                    skillTestSource
                    (SkillTestInitiatorTarget skillTestTarget)
                    skillTestSkillType
                    difficulty
                )
             , chooseOne skillTestInvestigator [SkillTestApplyResults]
             , SkillTestEnds skillTestSource
             ]
      pure $ s & resultL .~ FailedBy True difficulty
    StartSkillTest _ -> do
      windowMsg <- checkWindows [Window Timing.When Window.FastPlayerWindow]
      s
        <$ pushAll
          ( HashMap.foldMapWithKey
              (\k (i, _) -> [CommitCard i k])
              skillTestCommittedCards
              <> [windowMsg, TriggerSkillTest skillTestInvestigator]
          )
    InvestigatorCommittedSkill _ skillId ->
      pure $ s & subscribersL %~ (SkillTarget skillId :)
    SkillTestCommitCard iid cardId -> do
      card <- getCard cardId iid
      pure $ s & committedCardsL %~ insertMap cardId (iid, card)
    SkillTestUncommitCard _ cardId ->
      pure $ s & committedCardsL %~ deleteMap cardId
    ReturnSkillTestRevealedTokens -> do
      -- Rex's Curse timing keeps effects on stack so we do
      -- not want to remove them as subscribers from the stack
      push $ ResetTokens (toSource s)
      pure $
        s
          & (setAsideTokensL .~ mempty)
          & (revealedTokensL .~ mempty)
          & (resolvedTokensL .~ mempty)
    SkillTestEnds _ -> do
      -- Skill Cards are in the environment and will be discarded normally
      -- However, all other cards need to be discarded here.
      let discards =
            mapMaybe
              ( \case
                  (iid, PlayerCard pc) ->
                    (iid, pc) <$ guard (cdCardType (toCardDef pc) /= SkillType)
                  (_, EncounterCard _) -> Nothing
              )
              (s ^. committedCardsL . to toList)
          skillResultValue = case skillTestResult of
            Unrun -> error "wat, skill test has to run"
            SucceededBy _ n -> n
            FailedBy _ n -> (- n)

      skillTestEndsWindows <- windows [Window.SkillTestEnded s]
      s
        <$ pushAll
          ( ResetTokens (toSource s) :
            map (uncurry AddToDiscard) discards
              <> skillTestEndsWindows
              <> [ AfterSkillTestEnds
                    skillTestSource
                    skillTestTarget
                    skillResultValue
                 ]
          )
    SkillTestResults {} -> do
      push (chooseOne skillTestInvestigator [SkillTestApplyResults])
      case skillTestResult of
        SucceededBy _ n ->
          pushAll
            ( [ Will
                ( PassedSkillTest
                    skillTestInvestigator
                    skillTestAction
                    skillTestSource
                    target
                    skillTestSkillType
                    n
                )
              | target <- skillTestSubscribers
              ]
                <> [ Will
                      ( PassedSkillTest
                          skillTestInvestigator
                          skillTestAction
                          skillTestSource
                          (SkillTestInitiatorTarget skillTestTarget)
                          skillTestSkillType
                          n
                      )
                   ]
            )
        FailedBy _ n ->
          pushAll
            ( [ Will
                ( FailedSkillTest
                    skillTestInvestigator
                    skillTestAction
                    skillTestSource
                    target
                    skillTestSkillType
                    n
                )
              | target <- skillTestSubscribers
              ]
                <> [ Will
                      ( FailedSkillTest
                          skillTestInvestigator
                          skillTestAction
                          skillTestSource
                          (SkillTestInitiatorTarget skillTestTarget)
                          skillTestSkillType
                          n
                      )
                   ]
            )
        Unrun -> pure ()
      pure s
    SkillTestApplyResultsAfter -> do
      -- ST.7 -- apply results
      push $ SkillTestEnds skillTestSource -- -> ST.8 -- Skill test ends
      case skillTestResult of
        SucceededBy _ n ->
          pushAll
            ( [ After
                ( PassedSkillTest
                    skillTestInvestigator
                    skillTestAction
                    skillTestSource
                    target
                    skillTestSkillType
                    n
                )
              | target <- skillTestSubscribers
              ]
                <> [ After
                      ( PassedSkillTest
                          skillTestInvestigator
                          skillTestAction
                          skillTestSource
                          (SkillTestInitiatorTarget skillTestTarget)
                          skillTestSkillType
                          n
                      )
                   ]
            )
        FailedBy _ n ->
          pushAll
            ( [ After
                ( FailedSkillTest
                    skillTestInvestigator
                    skillTestAction
                    skillTestSource
                    target
                    skillTestSkillType
                    n
                )
              | target <- skillTestSubscribers
              ]
                <> [ After
                      ( FailedSkillTest
                          skillTestInvestigator
                          skillTestAction
                          skillTestSource
                          (SkillTestInitiatorTarget skillTestTarget)
                          skillTestSkillType
                          n
                      )
                   ]
            )
        Unrun -> pure ()
      pure s
    SkillTestApplyResults -> do
      -- ST.7 Apply Results
      push SkillTestApplyResultsAfter
      modifiers' <- getModifiers (toSource s) (toTarget s)
      let successTimes = if DoubleSuccess `elem` modifiers' then 2 else 1
      s <$ case skillTestResult of
        SucceededBy _ n ->
          pushAll $
            cycleN
              successTimes
              ( [ PassedSkillTest
                  skillTestInvestigator
                  skillTestAction
                  skillTestSource
                  target
                  skillTestSkillType
                  n
                | target <- skillTestSubscribers
                ]
                  <> [ PassedSkillTest
                        skillTestInvestigator
                        skillTestAction
                        skillTestSource
                        (SkillTestInitiatorTarget skillTestTarget)
                        skillTestSkillType
                        n
                     ]
              )
        FailedBy _ n ->
          pushAll
            ( [ When
                  ( FailedSkillTest
                      skillTestInvestigator
                      skillTestAction
                      skillTestSource
                      (SkillTestInitiatorTarget skillTestTarget)
                      skillTestSkillType
                      n
                  )
              ]
                <> [ When
                    ( FailedSkillTest
                        skillTestInvestigator
                        skillTestAction
                        skillTestSource
                        target
                        skillTestSkillType
                        n
                    )
                   | target <- skillTestSubscribers
                   ]
                <> [ FailedSkillTest
                    skillTestInvestigator
                    skillTestAction
                    skillTestSource
                    target
                    skillTestSkillType
                    n
                   | target <- skillTestSubscribers
                   ]
                <> [ FailedSkillTest
                      skillTestInvestigator
                      skillTestAction
                      skillTestSource
                      (SkillTestInitiatorTarget skillTestTarget)
                      skillTestSkillType
                      n
                   ]
            )
        Unrun -> pure ()
    RerunSkillTest -> case skillTestResult of
      FailedBy True _ -> pure s
      _ -> do
        withQueue_ $
          filter $ \case
            Will FailedSkillTest {} -> False
            Will PassedSkillTest {} -> False
            CheckWindow _ [Window Timing.When (Window.WouldFailSkillTest _)] ->
              False
            CheckWindow _ [Window Timing.When (Window.WouldPassSkillTest _)] ->
              False
            RunWindow _ [Window Timing.When (Window.WouldPassSkillTest _)] ->
              False
            RunWindow _ [Window Timing.When (Window.WouldFailSkillTest _)] ->
              False
            Ask skillTestInvestigator' (ChooseOne [SkillTestApplyResults])
              | skillTestInvestigator == skillTestInvestigator' -> False
            _ -> True
        push (RunSkillTest skillTestInvestigator)
        -- We need to subtract the current token values to prevent them from
        -- doubling. However, we need to keep any existing value modifier on
        -- the stack (such as a token no longer visible who effect still
        -- persists)
        tokenValues <-
          sum
            <$> for
              (skillTestRevealedTokens <> skillTestResolvedTokens)
              (getModifiedTokenValue s)
        pure $ s & valueModifierL %~ subtract tokenValues
    RunSkillTest _ -> do
      modifiers' <- getModifiers (toSource s) SkillTestTarget
      tokenValues <-
        sum
          <$> for
            (skillTestRevealedTokens <> skillTestResolvedTokens)
            (getModifiedTokenValue s)
      stats <- modifiedStatsOf (toSource s) skillTestAction skillTestInvestigator
      modifiedSkillTestDifficulty <- getModifiedSkillTestDifficulty s
      iconCount <-
        if CancelSkills `elem` modifiers'
          then pure 0
          else skillIconCount s
      let currentSkillValue = statsSkillValue stats skillTestSkillType
          totaledTokenValues = tokenValues + skillTestValueModifier
          modifiedSkillValue' =
            max 0 (currentSkillValue + totaledTokenValues + iconCount)
      push $
        SkillTestResults
          currentSkillValue
          iconCount
          totaledTokenValues
          modifiedSkillTestDifficulty
      if modifiedSkillValue' >= modifiedSkillTestDifficulty
        then
          pure $
            s
              & ( resultL
                    .~ SucceededBy
                      False
                      (modifiedSkillValue' - modifiedSkillTestDifficulty)
                )
              & (valueModifierL .~ totaledTokenValues)
        else
          pure $
            s
              & ( resultL
                    .~ FailedBy
                      False
                      (modifiedSkillTestDifficulty - modifiedSkillValue')
                )
              & (valueModifierL .~ totaledTokenValues)
    _ -> pure s

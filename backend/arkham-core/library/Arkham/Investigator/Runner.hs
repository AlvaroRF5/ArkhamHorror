{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.Investigator.Runner (
  module Arkham.Investigator.Runner,
  module X,
) where

import Arkham.Prelude

import Arkham.Ability as X hiding (PaidCost)
import Arkham.ChaosToken as X
import Arkham.ClassSymbol as X
import Arkham.Classes as X
import Arkham.Helpers.Investigator as X
import Arkham.Helpers.Message as X hiding (
  InvestigatorDamage,
  InvestigatorDefeated,
  InvestigatorResigned,
 )
import Arkham.Helpers.Query as X
import Arkham.Investigator.Types as X
import Arkham.Name as X
import Arkham.Source as X
import Arkham.Stats as X
import Arkham.Target as X
import Arkham.Trait as X hiding (Cultist)

import Arkham.Action (Action)
import Arkham.Action qualified as Action
import Arkham.Action.Additional
import Arkham.Asset.Types (Field (..))
import Arkham.Card
import Arkham.Card.PlayerCard
import Arkham.Classes.HasGame
import Arkham.CommitRestriction
import Arkham.Cost qualified as Cost
import Arkham.Damage
import Arkham.DamageEffect
import Arkham.Deck qualified as Deck
import Arkham.DefeatedBy
import Arkham.Discard
import Arkham.Draw.Types
import Arkham.Enemy.Types qualified as Field
import Arkham.Event.Types (Field (..))
import {-# SOURCE #-} Arkham.Game (withoutCanModifiers)
import Arkham.Game.Helpers hiding (windows)
import Arkham.Game.Helpers qualified as Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers
import Arkham.Helpers.Card (extendedCardMatch, iconsForCard)
import Arkham.Helpers.Deck qualified as Deck
import Arkham.Id
import Arkham.Investigate.Types
import Arkham.Investigator.Types qualified as Attrs
import Arkham.Key
import Arkham.Location.Types (Field (..))
import Arkham.Matcher (
  AssetMatcher (..),
  CardMatcher (..),
  EnemyMatcher (..),
  EventMatcher (..),
  InvestigatorMatcher (..),
  LocationMatcher (..),
  assetControlledBy,
  assetIs,
  colocatedWith,
  treacheryInHandOf,
 )
import Arkham.Message qualified as Msg
import Arkham.Modifier qualified as Modifier
import Arkham.Movement
import Arkham.Placement
import Arkham.Projection
import Arkham.ScenarioLogKey
import Arkham.Skill.Types (Field (..))
import Arkham.SkillTest
import Arkham.Token
import Arkham.Token qualified as Token
import Arkham.Treachery.Types (Field (..))
import Arkham.Window (Window (..), mkAfter, mkWhen, mkWindow)
import Arkham.Window qualified as Window
import Arkham.Zone qualified as Zone
import Control.Lens (each, non, over)
import Data.Data.Lens (biplate)
import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Monoid
import Data.UUID (nil)

instance RunMessage InvestigatorAttrs where
  runMessage = runInvestigatorMessage

onlyCampaignAbilities :: UsedAbility -> Bool
onlyCampaignAbilities UsedAbility {..} = case abilityLimitType (abilityLimit usedAbility) of
  Just PerCampaign -> True
  _ -> False

-- There are a few conditions that can occur that mean we must need to use an ability.
-- No valid targets. For example Marksmanship
-- Can't afford card. For example On Your Own
getAllAbilitiesSkippable :: HasGame m => InvestigatorAttrs -> [Window] -> m Bool
getAllAbilitiesSkippable attrs windows = allM (getWindowSkippable attrs windows) windows

getWindowSkippable :: HasGame m => InvestigatorAttrs -> [Window] -> Window -> m Bool
getWindowSkippable attrs ws (windowType -> Window.PlayCard iid card@(PlayerCard pc)) | iid == toId attrs = do
  modifiers' <- getModifiers (toCardId card)
  modifiers'' <- getModifiers (CardTarget card)
  cost <- getModifiedCardCost iid card
  let allModifiers = modifiers' <> modifiers''
  let isFast = isJust (cdFastWindow $ toCardDef pc) || BecomesFast `elem` allModifiers
  andM
    [ withAlteredGame withoutCanModifiers
        $ getCanAffordCost (toId attrs) pc [#play] ws (ResourceCost cost)
    , if isFast
        then pure True
        else getCanAffordCost (toId attrs) pc [#play] ws (ActionCost 1)
    ]
getWindowSkippable _ _ w@(windowType -> Window.ActivateAbility iid _ ab) = do
  let
    excludeOne [] = []
    excludeOne (uab : xs) | ab == usedAbility uab = do
      if usedTimes uab <= 1
        then xs
        else uab {usedTimes = usedTimes uab - 1} : xs
    excludeOne (uab : xs) = uab : excludeOne xs
  andM
    [ getCanAffordUseWith excludeOne CanNotIgnoreAbilityLimit iid ab w
    , withAlteredGame withoutCanModifiers
        $ passesCriteria iid Nothing (abilitySource ab) [w] (abilityCriteria ab)
    ]
getWindowSkippable attrs ws (windowType -> Window.WouldPayCardCost iid _ _ card@(PlayerCard pc)) | iid == toId attrs = do
  modifiers' <- getModifiers (toCardId card)
  modifiers'' <- getModifiers (CardTarget card)
  cost <- getModifiedCardCost iid card
  let allModifiers = modifiers' <> modifiers''
  let isFast = isJust (cdFastWindow $ toCardDef pc) || BecomesFast `elem` allModifiers
  andM
    [ withAlteredGame withoutCanModifiers
        $ getCanAffordCost (toId attrs) pc [#play] ws (ResourceCost cost)
    , if isFast
        then pure True
        else getCanAffordCost (toId attrs) pc [#play] ws (ActionCost 1)
    ]
getWindowSkippable _ _ _ = pure True

getHealthDamageableAssets
  :: HasGame m
  => InvestigatorId
  -> AssetMatcher
  -> Int
  -> [Target]
  -> [Target]
  -> m (Set AssetId)
getHealthDamageableAssets _ _ 0 _ _ = pure mempty
getHealthDamageableAssets iid matcher _ damageTargets horrorTargets = do
  allAssets <- select $ matcher <> AssetCanBeAssignedDamageBy iid
  excludes <- do
    modifiers <- getModifiers iid
    excludeMatchers <- forMaybeM modifiers $ \case
      NoMoreThanOneDamageOrHorrorAmongst excludeMatcher -> do
        excludes <- selectMap AssetTarget excludeMatcher
        pure $ do
          guard $ any (`elem` excludes) (damageTargets <> horrorTargets)
          pure excludeMatcher
      _ -> pure Nothing
    case excludeMatchers of
      [] -> pure mempty
      xs -> select (AssetOneOf xs)
  pure $ setFromList $ filter (`notElem` excludes) allAssets

getSanityDamageableAssets
  :: HasGame m
  => InvestigatorId
  -> AssetMatcher
  -> Int
  -> [Target]
  -> [Target]
  -> m (Set AssetId)
getSanityDamageableAssets _ _ 0 _ _ = pure mempty
getSanityDamageableAssets iid matcher _ damageTargets horrorTargets = do
  allAssets <- select $ matcher <> AssetCanBeAssignedHorrorBy iid
  excludes <- do
    modifiers <- getModifiers iid
    excludeMatchers <- forMaybeM modifiers $ \case
      NoMoreThanOneDamageOrHorrorAmongst excludeMatcher -> do
        excludes <- selectMap AssetTarget excludeMatcher
        pure $ do
          guard $ any (`elem` excludes) (damageTargets <> horrorTargets)
          pure excludeMatcher
      _ -> pure Nothing
    case excludeMatchers of
      [] -> pure mempty
      xs -> select (AssetOneOf xs)
  pure $ setFromList $ filter (`notElem` excludes) allAssets

runWindow
  :: (HasGame m, HasQueue Message m) => InvestigatorAttrs -> [Window] -> [Ability] -> [Card] -> m ()
runWindow attrs windows actions playableCards = do
  let iid = toId attrs
  unless (null playableCards && null actions) $ do
    anyForced <- anyM (isForcedAbility iid) actions
    player <- getPlayer iid
    if anyForced
      then do
        let
          (silent, normal) = partition isSilentForcedAbility actions
          toForcedAbilities = map (($ windows) . UseAbility iid)
          toUseAbilities = map ((\f -> f windows []) . AbilityLabel iid)
        -- Silent forced abilities should trigger automatically
        pushAll
          $ toForcedAbilities silent
          <> [chooseOne player (toUseAbilities normal) | notNull normal]
          <> [RunWindow iid windows]
      else do
        actionsWithMatchingWindows <-
          for actions $ \ability@Ability {..} ->
            (ability,)
              <$> filterM
                ( \w -> windowMatches iid abilitySource w abilityWindow
                )
                windows
        skippable <- getAllAbilitiesSkippable attrs windows
        push
          $ chooseOne player
          $ [ targetLabel (toCardId c)
              $ [ InitiatePlayCard iid c Nothing windows True
                , RunWindow iid windows
                ]
            | c <- playableCards
            ]
          <> map
            (\(ability, windows') -> AbilityLabel iid ability windows' [RunWindow iid windows])
            actionsWithMatchingWindows
          <> [Label "Skip playing fast cards or using reactions" [] | skippable]

runInvestigatorMessage :: Runner InvestigatorAttrs
runInvestigatorMessage msg a@InvestigatorAttrs {..} = case msg of
  EndCheckWindow -> do
    depth <- getWindowDepth
    let
      filterAbility UsedAbility {..} = do
        limit <- getAbilityLimit (toId a) usedAbility
        pure $ case limit of
          NoLimit -> False
          PlayerLimit PerWindow _ -> depth > usedDepth
          GroupLimit PerWindow _ -> depth > usedDepth
          _ -> True

    usedAbilities' <- filterM filterAbility investigatorUsedAbilities

    pure $ a & usedAbilitiesL .~ usedAbilities'
  ResetGame ->
    pure
      $ (cbCardBuilder (investigator id (toCardDef a) (getAttrStats a)) nullCardId investigatorPlayerId)
        { Attrs.investigatorId = investigatorId
        , investigatorXp = investigatorXp
        , investigatorPhysicalTrauma = investigatorPhysicalTrauma
        , investigatorMentalTrauma = investigatorMentalTrauma
        , investigatorTokens =
            addTokens Horror investigatorMentalTrauma $ addTokens Token.Damage investigatorPhysicalTrauma mempty
        , investigatorStartsWith = investigatorStartsWith
        , investigatorStartsWithInHand = investigatorStartsWithInHand
        , investigatorSupplies = investigatorSupplies
        , investigatorUsedAbilities = filter onlyCampaignAbilities investigatorUsedAbilities
        }
  SetupInvestigator iid | iid == investigatorId -> do
    (startsWithMsgs, deck') <-
      foldM
        ( \(msgs, currentDeck) cardDef -> do
            let (before, after) = break ((== cardDef) . toCardDef) (unDeck currentDeck)
            case after of
              (card : rest) ->
                pure
                  ( PutCardIntoPlay
                      investigatorId
                      (toCard card)
                      Nothing
                      (Window.defaultWindows investigatorId)
                      : msgs
                  , Deck (before <> rest)
                  )
              _ -> do
                card <- setOwner investigatorId =<< genCard cardDef
                pure
                  ( PutCardIntoPlay
                      investigatorId
                      card
                      Nothing
                      (Window.defaultWindows investigatorId)
                      : msgs
                  , currentDeck
                  )
        )
        ([], investigatorDeck)
        investigatorStartsWith
    let (permanentCards, deck'') = partition (cdPermanent . toCardDef) (unDeck deck')
    let deck''' = filter ((`notElem` investigatorStartsWithInHand) . toCardDef) deck''

    let bonded = nub $ concatMap (cdBondedWith . toCardDef) (unDeck investigatorDeck)

    bondedCards <- concatForM bonded $ \(n, cCode) -> do
      case lookupCardDef cCode of
        Nothing -> error "missing card"
        Just def -> do
          cs <- replicateM n (genCard def)
          traverse (setOwner iid) cs

    pushAll
      $ startsWithMsgs
      <> [ PutCardIntoPlay investigatorId (PlayerCard card) Nothing (Window.defaultWindows investigatorId)
         | card <- permanentCards
         ]
      <> [TakeStartingResources investigatorId]
    pure $ a & (deckL .~ Deck deck''') & bondedCardsL .~ bondedCards
  DrawStartingHand iid | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    if any (`elem` modifiers') [CannotDrawCards, CannotManipulateDeck]
      then pure a
      else do
        let
          startingHandAmount = foldr applyModifier 5 modifiers'
          applyModifier (StartingHand m) n = max 0 (n + m)
          applyModifier _ n = n
        (discard, hand, deck) <- drawOpeningHand a startingHandAmount
        pure
          $ a
          & (discardL .~ discard)
          & (handL .~ hand)
          & (deckL .~ Deck deck)
  ReturnToHand iid (AssetTarget aid) | iid == investigatorId -> do
    pure $ a & (slotsL %~ removeFromSlots aid)
  ReturnToHand iid (CardTarget card) | iid == investigatorId -> do
    -- Card is assumed to be in your discard
    -- but since find card can also return cards in your hand
    -- we filter again just in case
    let
      discardFilter = case preview _PlayerCard card of
        Just pc -> filter (/= pc)
        Nothing -> id
    pure
      $ a
      & (discardL %~ discardFilter)
      & (handL %~ filter (/= card))
      & (handL %~ (card :))
  CheckAdditionalActionCosts iid _ action msgs | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    let
      additionalCosts =
        mapMaybe
          ( \case
              ActionCostOf (IsAction action') n | action == action' -> Just (ActionCost n)
              _ -> Nothing
          )
          modifiers'
    if null additionalCosts
      then pushAll msgs
      else do
        canPay <-
          getCanAffordCost iid a [] [mkWhen Window.NonFast] (mconcat additionalCosts)
        when canPay
          $ pushAll
          $ [PayForAbility (abilityEffect a $ mconcat additionalCosts) []]
          <> msgs
    pure a
  TakeStartingResources iid | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    let
      startingResources =
        foldl'
          ( \total -> \case
              StartingResources n -> max 0 (total + n)
              _ -> total
          )
          5
          modifiers'
      startingClues =
        foldl'
          ( \total -> \case
              StartingClues n -> max 0 (total + n)
              _ -> total
          )
          0
          modifiers'
    pure $ a & tokensL %~ (setTokens Resource startingResources . setTokens Clue startingClues)
  InvestigatorMulligan iid | iid == investigatorId -> do
    unableToMulligan <- hasModifier a CannotMulligan
    hand <- field InvestigatorHand iid
    player <- getPlayer iid
    push
      $ if null hand || unableToMulligan
        then FinishedWithMulligan investigatorId
        else
          chooseOne player
            $ Label "Done With Mulligan" [FinishedWithMulligan investigatorId]
            : [ targetLabel (toCardId card)
                $ [DiscardCard iid GameSource (toCardId card), InvestigatorMulligan iid]
              | card <- hand
              , cdCanReplace (toCardDef card)
              ]
    pure a
  BeginTrade iid _source (AssetTarget aid) iids | iid == investigatorId -> do
    player <- getPlayer iid
    push $ chooseOne player [targetLabel iid' [TakeControlOfAsset iid' aid] | iid' <- iids]
    pure a
  BeginTrade iid source ResourceTarget iids | iid == investigatorId -> do
    player <- getPlayer iid
    push
      $ chooseOne player
      $ [targetLabel iid' [TakeResources iid' 1 source False, SpendResources iid 1] | iid' <- iids]
    pure a
  PlaceSwarmCards iid eid n | iid == investigatorId && n > 0 -> do
    let cards = map toCard . take n $ unDeck investigatorDeck
    for_ cards $ push . PlacedSwarmCard eid
    pure $ a & (deckL %~ filter ((`notElem` cards) . PlayerCard))
  SetRole iid role | iid == investigatorId -> do
    pure $ a {investigatorClass = role}
  AllRandomDiscard source matcher | not (a ^. defeatedL || a ^. resignedL) -> do
    push $ toMessage $ randomDiscardMatching investigatorId source matcher
    pure a
  FinishedWithMulligan iid | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    let
      allowedMulligans =
        foldl'
          ( \total -> \case
              Mulligans n -> max 0 (total + n)
              _ -> total
          )
          1
          modifiers'
      startingHandAmount =
        foldl'
          ( \total -> \case
              StartingHand n -> max 0 (total + n)
              _ -> total
          )
          5
          modifiers'
      startingResources =
        foldl'
          ( \total -> \case
              StartingResources n -> max 0 (total + n)
              _ -> total
          )
          5
          modifiers'
      additionalStartingCards = concat $ mapMaybe (preview _AdditionalStartingCards) modifiers'
    -- investigatorHand is dangerous, but we want to use it here because we're
    -- only affecting cards actually in hand [I think]
    (discard, hand, deck) <-
      if any (`elem` modifiers') [CannotDrawCards, CannotManipulateDeck]
        then pure (investigatorDiscard, investigatorHand, unDeck investigatorDeck)
        else drawOpeningHand a (startingHandAmount - length investigatorHand)
    window <- checkWindows [mkAfter (Window.DrawingStartingHand iid)]
    additionalHandCards <-
      (additionalStartingCards <>) <$> traverse genCard investigatorStartsWithInHand

    -- if we have any cards with revelations on them, we need to trigger them
    let revelationCards = filter (hasRevelation . toCardDef) (additionalHandCards <> hand)
    let
      choices = mapMaybe cardChoice revelationCards
      cardChoice = \case
        card@(PlayerCard card') -> do
          if hasRevelation card'
            then
              if toCardType card' == PlayerTreacheryType
                then Just (card, DrewTreachery iid Nothing card)
                else Just (card, Revelation iid $ PlayerCardSource card')
            else
              if toCardType card' == PlayerEnemyType
                then Just (card, DrewPlayerEnemy iid card)
                else Nothing
        _ -> Nothing

    -- need the virtual hand to get correct length
    hand' <- field InvestigatorHand iid

    player <- getPlayer iid
    pushAll
      $ [ShuffleDiscardBackIn iid, window]
      <> [ chooseOrRunOneAtATime player [targetLabel (toCardId card) [msg'] | (card, msg') <- choices]
         | notNull choices
         ]
      <> [ InvestigatorMulligan iid
         | (a ^. mulligansTakenL + 1) < allowedMulligans
         , startingHandAmount - length hand' > 0
         ]
    pure
      $ a
      & (tokensL %~ setTokens Resource startingResources)
      & (discardL .~ discard)
      & (handL .~ hand <> additionalHandCards)
      & (deckL .~ Deck deck)
      & (mulligansTakenL +~ 1)
  ShuffleDiscardBackIn iid | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    if null investigatorDiscard || CardsCannotLeaveYourDiscardPile `elem` modifiers'
      then pure a
      else do
        deck <- shuffleM (investigatorDiscard <> coerce investigatorDeck)
        pure $ a & discardL .~ [] & deckL .~ Deck deck
  Resign iid | iid == investigatorId -> do
    isLead <- (== iid) <$> getLeadInvestigatorId
    pushAll $ [ChooseLeadInvestigator | isLead] <> resolve (Msg.InvestigatorResigned iid)
    pure $ a & resignedL .~ True & endedTurnL .~ True
  Msg.InvestigatorDefeated source iid -> do
    -- a card effect defeats an investigator directly
    windowMsg <-
      checkWindows [mkWhen $ Window.InvestigatorWouldBeDefeated (DefeatedByOther source) (toId a)]
    pushAll [windowMsg, InvestigatorIsDefeated source iid]
    pure a
  InvestigatorIsDefeated source iid | iid == investigatorId -> do
    isLead <- (== iid) <$> getLeadInvestigatorId
    modifiedHealth <- field InvestigatorHealth (toId a)
    modifiedSanity <- field InvestigatorSanity (toId a)
    let
      defeatedByHorror = investigatorSanityDamage a >= modifiedSanity
      defeatedByDamage = investigatorHealthDamage a >= modifiedHealth
      defeatedBy = case (defeatedByHorror, defeatedByDamage) of
        (True, True) -> DefeatedByDamageAndHorror source
        (True, False) -> DefeatedByHorror source
        (False, True) -> DefeatedByDamage source
        (False, False) -> DefeatedByOther source
      physicalTrauma =
        if investigatorHealthDamage a >= modifiedHealth then 1 else 0
      mentalTrauma =
        if investigatorSanityDamage a >= modifiedSanity then 1 else 0
    windowMsg <- checkWindows [mkAfter $ Window.InvestigatorDefeated defeatedBy iid]
    killed <- hasModifier a KilledIfDefeated
    pushAll
      $ windowMsg
      : [ChooseLeadInvestigator | isLead]
        <> [InvestigatorKilled (toSource a) iid | killed]
        <> [InvestigatorWhenEliminated (toSource a) iid]
    pure
      $ a
      & (defeatedL .~ True)
      & (endedTurnL .~ True)
      & (physicalTraumaL +~ physicalTrauma)
      & (mentalTraumaL +~ mentalTrauma)
  Msg.InvestigatorResigned iid | iid == investigatorId -> do
    isLead <- (== iid) <$> getLeadInvestigatorId
    pushAll
      $ [ChooseLeadInvestigator | isLead && not investigatorResigned]
      <> [InvestigatorWhenEliminated (toSource a) iid]
    pure $ a & resignedL .~ True & endedTurnL .~ True
  -- InvestigatorWhenEliminated is handled by the scenario
  InvestigatorEliminated iid | iid == investigatorId -> do
    mlid <- field InvestigatorLocation iid
    pushAll
      $ [PlaceTokens (toSource a) (toTarget lid) Clue (investigatorClues a) | lid <- toList mlid]
      <> [PlaceKey (toTarget lid) k | k <- toList investigatorKeys, lid <- toList mlid]
    pure $ a & tokensL %~ (removeAllTokens Clue . removeAllTokens Resource) & keysL .~ mempty
  RemoveAllClues _ (InvestigatorTarget iid) | iid == investigatorId -> do
    pure $ a & tokensL %~ removeAllTokens Clue
  RemovedFromPlay source@(AssetSource aid) -> do
    -- TODO: Do we need to refill slots?
    pure $ a & (slotsL . each %~ filter ((/= source) . slotSource)) & (slotsL %~ removeFromSlots aid)
  TakeControlOfAsset iid aid | iid == investigatorId -> do
    a <$ push (InvestigatorPlayAsset iid aid)
  TakeControlOfAsset iid aid | iid /= investigatorId -> do
    pure $ a & (slotsL %~ removeFromSlots aid)
  ChooseAndDiscardAsset iid source assetMatcher | iid == investigatorId -> do
    discardableAssetIds <- select $ assetMatcher <> DiscardableAsset <> assetControlledBy iid
    player <- getPlayer iid
    push
      $ chooseOrRunOne player
      $ map (\aid -> targetLabel aid [toDiscardBy iid source aid]) discardableAssetIds
    pure a
  AttachAsset aid _ -> do
    pure $ a & (slotsL %~ removeFromSlots aid)
  PlaceAsset aid placement -> do
    case placement of
      InPlayArea iid | iid == investigatorId -> do
        push $ InvestigatorPlayAsset iid aid
        pure a
      _ -> pure $ a & (slotsL %~ removeFromSlots aid)
  PlaceKey (isTarget a -> True) k -> do
    pure $ a & keysL %~ insertSet k
  PlaceKey (isTarget a -> False) k -> do
    pure $ a & keysL %~ deleteSet k
  AllCheckHandSize | not (a ^. defeatedL || a ^. resignedL) -> do
    handSize <- getHandSize a
    inHandCount <- getInHandCount a
    pushWhen (inHandCount > handSize) $ CheckHandSize investigatorId
    pure a
  CheckHandSize iid | iid == investigatorId -> do
    handSize <- getHandSize a
    inHandCount <- getInHandCount a
    when (inHandCount > handSize) $ do
      send $ format a <> " must discard down to " <> tshow handSize <> " cards"
      push $ Do msg
    pure a
  Do (CheckHandSize iid) | iid == investigatorId -> do
    handSize <- getHandSize a
    inHandCount <- getInHandCount a
    -- investigatorHand: can only discard cards actually in hand
    player <- getPlayer iid
    pushWhen (inHandCount > handSize)
      $ chooseOne player
      $ [ targetLabel (toCardId card) [DiscardCard iid GameSource (toCardId card), Do (CheckHandSize iid)]
        | card <- filter (isNothing . cdCardSubType . toCardDef) $ onlyPlayerCards investigatorHand
        ]
    pure a
  AddToDiscard iid pc | iid == investigatorId -> do
    let
      discardF =
        if toCardCode pc == "06113"
          then bondedCardsL %~ (toCard pc :)
          else discardL %~ (pc :)
    pure $ a & discardF & (foundCardsL . each %~ filter (/= PlayerCard pc))
  DiscardFromHand handDiscard | discardInvestigator handDiscard == investigatorId -> do
    push $ DoneDiscarding investigatorId
    case discardStrategy handDiscard of
      DiscardChoose -> case discardableCards a of
        [] -> pure ()
        cs -> do
          player <- getPlayer investigatorId
          pushAll
            $ replicate (discardAmount handDiscard)
            $ chooseOrRunOne player
            $ [ targetLabel (toCardId c) [DiscardCard investigatorId (discardSource handDiscard) (toCardId c)]
              | c <- filter (`cardMatch` discardFilter handDiscard) cs
              ]
      DiscardRandom -> do
        -- only cards actually in hand
        let filtered = filter (`cardMatch` discardFilter handDiscard) investigatorHand
        for_ (nonEmpty filtered) $ \targets -> do
          cards <- sampleN (discardAmount handDiscard) targets
          pushAll $ map (DiscardCard investigatorId (discardSource handDiscard) . toCardId) cards
    pure $ a & discardingL ?~ handDiscard
  Discard _ source (CardIdTarget cardId) | isJust (find ((== cardId) . toCardId) investigatorHand) -> do
    push (DiscardCard investigatorId source cardId)
    pure a
  Discard _ source (CardTarget card) | card `elem` investigatorHand -> do
    push $ DiscardCard investigatorId source (toCardId card)
    pure a
  Discard _ _ (SearchedCardTarget cardId) -> do
    pure $ a & foundCardsL . each %~ filter ((/= cardId) . toCardId)
  DiscardHand iid source | iid == investigatorId -> do
    pushAll $ map (DiscardCard iid source . toCardId) investigatorHand
    pure a
  DiscardCard iid source cardId | iid == investigatorId -> do
    let card = fromJustNote "must be in hand" $ find ((== cardId) . toCardId) investigatorHand
    inMulligan <- getInMulligan
    beforeWindowMsg <- checkWindows [mkWhen (Window.Discarded iid source card)]
    afterWindowMsg <- checkWindows [mkAfter (Window.Discarded iid source card)]
    if inMulligan
      then push (Do msg)
      else pushAll [beforeWindowMsg, Do msg, afterWindowMsg]
    pure a
  Do (DiscardCard iid _source cardId) | iid == investigatorId -> do
    let card = fromJustNote "must be in hand" $ find ((== cardId) . toCardId) investigatorHand
    case card of
      PlayerCard pc -> do
        let
          updateHandDiscard handDiscard =
            handDiscard
              { discardAmount = max 0 (discardAmount handDiscard - 1)
              }
          discardF =
            if toCardCode pc == "06113"
              then bondedCardsL %~ (toCard pc :)
              else discardL %~ (pc :)
        pure
          $ a
          & handL
          %~ filter (/= card)
          & discardF
          & discardingL
          %~ fmap updateHandDiscard
      EncounterCard _ -> pure $ a & handL %~ filter (/= card) -- TODO: This should discard to the encounter discard
      VengeanceCard _ -> error "vengeance card"
  DoneDiscarding iid | iid == investigatorId -> case investigatorDiscarding of
    Nothing -> pure a
    Just handDiscard -> do
      when (discardAmount handDiscard == 0)
        $ for_ (discardThen handDiscard) push
      pure $ a & discardingL .~ Nothing
  RemoveCardFromHand iid cardId | iid == investigatorId -> do
    pure $ a & handL %~ filter ((/= cardId) . toCardId)
  RemoveCardFromSearch iid cardId | iid == investigatorId -> do
    pure $ a & foundCardsL %~ Map.map (filter ((/= cardId) . toCardId))
  ShuffleIntoDeck (Deck.InvestigatorDeck iid) (AssetTarget aid) | iid == investigatorId -> do
    card <- fromJustNote "missing card" . preview _PlayerCard <$> field AssetCard aid
    deck' <- shuffleM (card : unDeck investigatorDeck)
    push $ After msg
    pure
      $ a
      & (deckL .~ Deck deck')
      & (slotsL %~ removeFromSlots aid)
  ShuffleIntoDeck (Deck.InvestigatorDeck iid) (EventTarget eid) | iid == investigatorId -> do
    card <- fromJustNote "missing card" . preview _PlayerCard <$> field EventCard eid
    deck' <- shuffleM (card : unDeck investigatorDeck)
    push $ After msg
    pure $ a & (deckL .~ Deck deck')
  ShuffleIntoDeck (Deck.InvestigatorDeck iid) (SkillTarget aid) | iid == investigatorId -> do
    card <- fromJustNote "missing card" . preview _PlayerCard <$> field SkillCard aid
    if toCardCode card == "06113"
      then pure $ a & (bondedCardsL %~ (toCard card :))
      else do
        deck' <- shuffleM (card : unDeck investigatorDeck)
        push $ After msg
        pure $ a & (deckL .~ Deck deck')
  Discarded (AssetTarget aid) _ (PlayerCard card) -> do
    -- TODO: This message is ugly, we should do something different
    -- TODO: There are a number of messages here that mean the asset is no longer in play, we should consolidate to a singular message
    let slotAssets = concatMap (concatMap slotItems) (Map.elems investigatorSlots)
    when (aid `elem` slotAssets) $ do
      -- if we are planning to discard another asset immediately, wait to refill slots
      mmsg <- peekMessage
      case mmsg of
        Just (Discard _ _ (AssetTarget aid')) | aid' `elem` slotAssets -> pure ()
        -- N.B. This is explicitly for Empower Self and it's possible we don't want to do this without checking
        _ -> push $ RefillSlots investigatorId

    let shouldDiscard = pcOwner card == Just investigatorId && card `notElem` investigatorDiscard

    pure
      $ a
      & (if shouldDiscard then (discardL %~ (card :)) else id)
      & (slotsL %~ removeFromSlots aid)
  -- Discarded _ _ (PlayerCard card) -> do
  --   let shouldDiscard = pcOwner card == Just investigatorId && card `notElem` investigatorDiscard
  --   if shouldDiscard
  --     then pure $ a & discardL %~ (card :) & handL %~ filter (/= PlayerCard card)
  --     else pure a
  Discarded (AssetTarget aid) _ (EncounterCard _) -> do
    pure $ a & (slotsL %~ removeFromSlots aid)
  Exiled (AssetTarget aid) _ -> do
    pure $ a & (slotsL %~ removeFromSlots aid)
  RemoveFromGame (AssetTarget aid) ->
    pure $ a & (slotsL %~ removeFromSlots aid)
  RemoveFromGame (CardIdTarget cid) ->
    pure $ a & cardsUnderneathL %~ filter ((/= cid) . toCardId)
  ChooseFightEnemy iid source mTarget skillType enemyMatcher isAction | iid == investigatorId -> do
    modifiers <- getModifiers (InvestigatorTarget iid)
    let
      isOverride = \case
        EnemyFightActionCriteria override -> Just override
        CanModify (EnemyFightActionCriteria override) -> Just override
        _ -> Nothing
      overrides = mapMaybe isOverride modifiers
      applyMatcherModifiers :: ModifierType -> EnemyMatcher -> EnemyMatcher
      applyMatcherModifiers (Modifier.AlternateFightField someField) original = case someField of
        SomeField Field.EnemyEvade -> original <> EnemyWithEvade
        _ -> original
      applyMatcherModifiers _ n = n
      canFightMatcher = case overrides of
        [] -> CanFightEnemy source
        [o] -> CanFightEnemyWithOverride o
        _ -> error "multiple overrides found"
    enemyIds <- select $ foldr applyMatcherModifiers (canFightMatcher <> enemyMatcher) modifiers
    player <- getPlayer iid
    push
      $ chooseOne
        player
        [ FightLabel eid [FightEnemy iid eid source mTarget skillType isAction]
        | eid <- enemyIds
        ]
    pure a
  EngageEnemy iid eid _ True | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    beforeWindowMsg <- checkWindows [mkWhen (Window.PerformAction iid #engage)]
    afterWindowMsg <- checkWindows [mkAfter (Window.PerformAction iid #engage)]

    pushAll
      $ [ BeginAction
        , beforeWindowMsg
        , TakeActions iid [#engage] (ActionCost 1)
        ]
      <> [ CheckAttackOfOpportunity iid False
         | ActionDoesNotCauseAttacksOfOpportunity #engage `notElem` modifiers'
         ]
      <> [EngageEnemy iid eid Nothing False, afterWindowMsg, FinishAction]
    pure a
  FightEnemy iid eid source mTarget skillType True | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    beforeWindowMsg <- checkWindows [mkWhen $ Window.PerformAction iid #fight]
    afterWindowMsg <- checkWindows [mkAfter $ Window.PerformAction iid #fight]
    let
      performedActions = setFromList @(Set Action) $ concat investigatorActionsPerformed
      -- takenActions = setFromList @(Set Action) investigatorActionsTaken
      applyFightCostModifiers :: Cost -> ModifierType -> Cost
      applyFightCostModifiers costToEnter (ActionCostOf actionTarget n) =
        case actionTarget of
          FirstOneOfPerformed as
            | #fight `elem` as
            , null (performedActions `intersect` setFromList as) -> do
                increaseActionCost costToEnter n
          IsAction Action.Fight -> increaseActionCost costToEnter n
          _ -> costToEnter
      applyFightCostModifiers costToEnter _ = costToEnter
    pushAll
      [ BeginAction
      , beforeWindowMsg
      , TakeActions iid [#fight] (foldl' applyFightCostModifiers (ActionCost 1) modifiers')
      , FightEnemy iid eid source mTarget skillType False
      , afterWindowMsg
      , FinishAction
      ]
    pure a
  FightEnemy iid eid source mTarget skillType False | iid == investigatorId -> do
    a <$ push (AttackEnemy iid eid source mTarget skillType)
  FailedAttackEnemy iid eid | iid == investigatorId -> do
    doesNotDamageOtherInvestigators <- hasModifier a DoesNotDamageOtherInvestigator
    unless doesNotDamageOtherInvestigators $ do
      investigatorIds <- select $ InvestigatorEngagedWith $ EnemyWithId eid
      case investigatorIds of
        [x] | x /= iid -> push (InvestigatorDamageInvestigator iid x)
        _ -> pure ()
    pure a
  PlaceAdditionalDamage target source damage horror | isTarget a target -> do
    push $ Msg.InvestigatorDamage (toId a) source damage horror
    pure a
  InvestigatorDamageInvestigator iid xid | iid == investigatorId -> do
    damage <- damageValueFor 1 iid
    push $ InvestigatorAssignDamage xid (InvestigatorSource iid) DamageAny damage 0
    pure a
  InvestigatorDamageEnemy iid eid source | iid == investigatorId -> do
    cannotDamage <- hasModifier iid CannotDealDamage
    unless cannotDamage $ do
      damage <- damageValueFor 1 iid
      push $ EnemyDamage eid $ attack source damage
    pure a
  EnemyEvaded iid eid | iid == investigatorId -> do
    push =<< checkWindows [mkAfter (Window.EnemyEvaded iid eid)]
    pure a
  ChooseEvadeEnemy iid source mTarget skillType enemyMatcher isAction | iid == investigatorId -> do
    modifiers <- getModifiers (InvestigatorTarget iid)
    let
      isOverride = \case
        EnemyEvadeActionCriteria override -> Just override
        CanModify (EnemyEvadeActionCriteria override) -> Just override
        _ -> Nothing
      overrides = mapMaybe isOverride modifiers
      applyMatcherModifiers :: ModifierType -> EnemyMatcher -> EnemyMatcher
      applyMatcherModifiers (Modifier.AlternateEvadeField someField) original = case someField of
        SomeField Field.EnemyEvade -> original <> EnemyWithEvade
        _ -> original
      applyMatcherModifiers _ n = n
      canEvadeMatcher = case overrides of
        [] -> CanEvadeEnemy source
        [o] -> CanEvadeEnemyWithOverride o
        _ -> error "multiple overrides found"
    enemyIds <- select $ foldr applyMatcherModifiers (canEvadeMatcher <> enemyMatcher) modifiers
    player <- getPlayer iid
    push
      $ chooseOne
        player
        [ EvadeLabel eid [EvadeEnemy iid eid source mTarget skillType isAction]
        | eid <- enemyIds
        ]
    pure a
  ChooseEngageEnemy iid source mTarget enemyMatcher isAction | iid == investigatorId -> do
    modifiers <- getModifiers (InvestigatorTarget iid)
    let
      isOverride = \case
        EnemyEngageActionCriteria override -> Just override
        CanModify (EnemyEngageActionCriteria override) -> Just override
        _ -> Nothing
      overrides = mapMaybe isOverride modifiers
      canEngageMatcher = case overrides of
        [] -> CanEngageEnemy source
        [o] -> CanEngageEnemyWithOverride o
        _ -> error "multiple overrides found"
    enemyIds <- select $ canEngageMatcher <> enemyMatcher
    player <- getPlayer iid
    push
      $ chooseOne
        player
        [ EngageLabel eid [EngageEnemy iid eid mTarget isAction]
        | eid <- enemyIds
        ]
    pure a
  EvadeEnemy iid eid source mTarget skillType True | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    beforeWindowMsg <- checkWindows [mkWhen $ Window.PerformAction iid #evade]
    afterWindowMsg <- checkWindows [mkAfter $ Window.PerformAction iid #evade]
    let
      performedActions = setFromList @(Set Action) $ concat investigatorActionsPerformed
      -- takenActions = setFromList @(Set Action) investigatorActionsTaken
      applyEvadeCostModifiers :: Cost -> ModifierType -> Cost
      applyEvadeCostModifiers costToEnter (ActionCostOf actionTarget n) =
        case actionTarget of
          FirstOneOfPerformed as
            | #evade `elem` as
            , null (performedActions `intersect` setFromList as) ->
                increaseActionCost costToEnter n
          IsAction Action.Evade -> increaseActionCost costToEnter n
          _ -> costToEnter
      applyEvadeCostModifiers costToEnter _ = costToEnter
    pushAll
      [ BeginAction
      , beforeWindowMsg
      , TakeActions iid [#evade] (foldl' applyEvadeCostModifiers (ActionCost 1) modifiers')
      , EvadeEnemy iid eid source mTarget skillType False
      , afterWindowMsg
      , FinishAction
      ]
    pure a
  EvadeEnemy iid eid source mTarget skillType False | iid == investigatorId -> do
    pushAll [TryEvadeEnemy iid eid source mTarget skillType, AfterEvadeEnemy iid eid]
    pure a
  MoveAction iid lid cost True | iid == investigatorId -> do
    beforeWindowMsg <- checkWindows [mkWhen (Window.PerformAction iid #move)]
    afterWindowMsg <- checkWindows [mkAfter (Window.PerformAction iid #move)]
    pushAll
      [ BeginAction
      , beforeWindowMsg
      , TakeActions iid [#move] cost
      , MoveAction iid lid cost False
      , afterWindowMsg
      , FinishAction
      ]
    pure a
  MoveAction iid lid _cost False | iid == investigatorId -> do
    from <- fromMaybe (LocationId nil) <$> field InvestigatorLocation iid
    afterWindowMsg <- Helpers.checkWindows [mkAfter $ Window.MoveAction iid from lid]
    -- exclude additional costs because they will have been paid by the action
    pushAll $ resolve (Move ((move (toSource a) iid lid) {movePayAdditionalCosts = False}))
      <> [afterWindowMsg]
    pure a
  Move movement | isTarget a (moveTarget movement) -> do
    case moveDestination movement of
      ToLocationMatching matcher -> do
        lids <- getCanMoveToMatchingLocations investigatorId (moveSource movement) matcher
        player <- getPlayer investigatorId
        push
          $ chooseOrRunOne player
          $ [targetLabel lid [Move $ movement {moveDestination = ToLocation lid}] | lid <- lids]
      ToLocation destinationLocationId -> do
        batchId <- getRandom

        let
          source = moveSource movement
          iid = investigatorId
        mFromLocation <- field InvestigatorLocation iid

        leaveCosts <- case mFromLocation of
          Nothing -> pure mempty
          Just lid ->
            if movePayAdditionalCosts movement
              then do
                mods' <- getModifiers lid
                pure $ mconcat [c | AdditionalCostToLeave c <- mods']
              else pure mempty

        -- TODO: we might care about other sources here
        enterCosts <- do
          if movePayAdditionalCosts movement
            then do
              mods' <- getModifiers destinationLocationId
              pure $ mconcat [c | AdditionalCostToEnter c <- mods']
            else pure mempty

        let
          (whenMoves, atIfMoves, afterMoves) = timings (Window.Moves iid source mFromLocation destinationLocationId)
          (mWhenLeaving, mAtIfLeaving, mAfterLeaving) = case mFromLocation of
            Just from ->
              batchedTimings batchId (Window.Leaving iid from) & \case
                (whens, atIfs, afters) -> (Just whens, Just atIfs, Just afters)
            Nothing -> (Nothing, Nothing, Nothing)
          (whenEntering, atIfEntering, afterEntering) = batchedTimings batchId (Window.Entering iid destinationLocationId)

        -- Windows we need to check as understood:
        -- according to Empirical Hypothesis ruling the order should be like:
        -- when {leaving} -> atIf {leaving} -> after {leaving} -> before {entering} -> atIf {entering} / when {move} -> atIf {move} -> Reveal Location -> after but before enemy engagement {entering} -> Check Enemy Engagement -> after {entering, move}
        -- move but before enemy engagement is handled in MoveTo

        mRunWhenLeaving <- case mWhenLeaving of
          Just whenLeaving -> Just <$> checkWindows [whenLeaving]
          Nothing -> pure Nothing
        mRunAtIfLeaving <- case mAtIfLeaving of
          Just atIfLeaving -> Just <$> checkWindows [atIfLeaving]
          Nothing -> pure Nothing
        mRunAfterLeaving <- case mAfterLeaving of
          Just afterLeaving -> Just <$> checkWindows [afterLeaving]
          Nothing -> pure Nothing
        runWhenMoves <- checkWindows [whenMoves]
        runAtIfMoves <- checkWindows [atIfMoves]
        runWhenEntering <- checkWindows [whenEntering]
        runAtIfEntering <- checkWindows [atIfEntering]
        runAfterEnteringMoves <- checkWindows [afterEntering, afterMoves]

        pushBatched batchId
          $ maybeToList mRunWhenLeaving
          <> maybeToList mRunAtIfLeaving
          <> [PayAdditionalCost iid batchId leaveCosts]
          <> [MoveFrom source iid fromLocationId | fromLocationId <- maybeToList mFromLocation]
          <> maybeToList mRunAfterLeaving
          <> [ runWhenEntering
             , runAtIfEntering
             , PayAdditionalCost iid batchId enterCosts
             , runWhenMoves
             , runAtIfMoves
             ]
          <> [MoveTo $ move source iid destinationLocationId]
          <> [runAfterEnteringMoves]
    pure a
  Will (PassedSkillTest iid _ _ (InvestigatorTarget iid') _ _) | iid == iid' && iid == investigatorId -> do
    pushM $ checkWindows [mkWhen (Window.WouldPassSkillTest iid)]
    pure a
  Will (FailedSkillTest iid _ _ (InvestigatorTarget iid') _ _) | iid == iid' && iid == toId a -> do
    pushM $ checkWindows [mkWhen (Window.WouldFailSkillTest iid)]
    pure a
  CancelDamage iid n | iid == investigatorId -> do
    withQueue_ \queue -> flip map queue $ \case
      Msg.InvestigatorDamage iid' s damage' horror' ->
        Msg.InvestigatorDamage iid' s (max 0 (damage' - n)) horror'
      InvestigatorDoAssignDamage iid' s t matcher' damage' horror' aa b ->
        InvestigatorDoAssignDamage iid' s t matcher' (max 0 (damage' - n)) horror' aa b
      other -> other
    pure a
  CancelHorror iid n | iid == investigatorId -> do
    withQueue_ \queue -> flip map queue $ \case
      Msg.InvestigatorDamage iid' s damage' horror' ->
        Msg.InvestigatorDamage iid' s damage' (max 0 (horror' - n))
      InvestigatorDoAssignDamage iid' s t matcher' damage' horror' aa b ->
        InvestigatorDoAssignDamage iid' s t matcher' damage' (max 0 (horror' - n)) aa b
      other -> other
    pure a
  InvestigatorDirectDamage iid source damage horror
    | iid == toId a
    , not (investigatorDefeated || investigatorResigned) -> do
        pushAll
          $ [ CheckWindow [iid]
              $ mkWhen (Window.WouldTakeDamageOrHorror source (toTarget a) damage horror)
              : [mkWhen (Window.WouldTakeDamage source (toTarget a) damage) | damage > 0]
                <> [mkWhen (Window.WouldTakeHorror source (toTarget a) horror) | horror > 0]
            | damage > 0 || horror > 0
            ]
          <> [ InvestigatorDoAssignDamage
                iid
                source
                DamageAny
                (AssetWithModifier CanBeAssignedDirectDamage)
                damage
                horror
                []
                []
             , checkDefeated source iid
             ]
        pure a
  InvestigatorAssignDamage iid source strategy damage horror
    | iid == toId a
    , not (investigatorDefeated || investigatorResigned) -> do
        modifiers <- getModifiers (toTarget a)
        if TreatAllDamageAsDirect `elem` modifiers
          then push $ InvestigatorDirectDamage iid source damage horror
          else
            pushAll
              $ [ CheckWindow [iid]
                  $ mkWhen (Window.WouldTakeDamageOrHorror source (toTarget a) damage horror)
                  : [mkWhen (Window.WouldTakeDamage source (toTarget a) damage) | damage > 0]
                    <> [mkWhen (Window.WouldTakeHorror source (toTarget a) horror) | horror > 0]
                | damage > 0 || horror > 0
                ]
              <> [ InvestigatorDoAssignDamage iid source strategy AnyAsset damage horror [] []
                 , checkDefeated source iid
                 ]
        pure a
  InvestigatorDoAssignDamage iid source damageStrategy _ 0 0 damageTargets horrorTargets | iid == toId a -> do
    let
      damageEffect = case source of
        EnemyAttackSource _ -> AttackDamageEffect
        _ -> NonAttackDamageEffect
      damageMap = frequencies damageTargets
      horrorMap = frequencies horrorTargets
      placedWindows =
        [ Window.PlacedDamage source target damage
        | (target, damage) <- mapToList damageMap
        ]
          <> [ Window.PlacedHorror source target horror
             | (target, horror) <- mapToList horrorMap
             ]
      checkAssets = nub $ keys horrorMap <> keys damageMap
    placedWindowMsg <-
      checkWindows $ concatMap (\t -> map (mkWindow t) placedWindows) [#when, #after]
    pushAll
      $ [ placedWindowMsg
        , CheckWindow [iid]
            $ [ mkWhen (Window.DealtDamage source damageEffect target damage)
              | target <- nub damageTargets
              , let damage = count (== target) damageTargets
              ]
            <> [ mkWhen (Window.DealtHorror source target horror)
               | target <- nub horrorTargets
               , let horror = count (== target) horrorTargets
               ]
            <> [mkWhen (Window.AssignedHorror source iid horrorTargets) | notNull horrorTargets]
        , CheckWindow [iid]
            $ [ mkAfter (Window.DealtDamage source damageEffect target damage)
              | target <- nub damageTargets
              , let damage = count (== target) damageTargets
              ]
            <> [ mkAfter (Window.DealtHorror source target horror)
               | target <- nub horrorTargets
               , let horror = count (== target) horrorTargets
               ]
            <> [mkAfter (Window.AssignedHorror source iid horrorTargets) | notNull horrorTargets]
        ]
      <> [CheckDefeated source (toTarget aid) | aid <- checkAssets]
    when
      ( damageStrategy
          == DamageFromHastur
          && toTarget a
          `elem` horrorTargets
          && investigatorSanityDamage a
          > investigatorSanity
      )
      $ push
      $ InvestigatorDirectDamage iid source 1 0
    pure a
  InvestigatorDoAssignDamage iid source DamageEvenly matcher health 0 damageTargets horrorTargets | iid == toId a -> do
    healthDamageableAssets <-
      toList
        <$> getHealthDamageableAssets
          iid
          matcher
          health
          damageTargets
          horrorTargets
    let
      getDamageTargets xs =
        if length xs >= length healthDamageableAssets + 1
          then getDamageTargets (drop (length healthDamageableAssets + 1) xs)
          else xs
      damageTargets' = getDamageTargets damageTargets
      healthDamageableAssets' =
        filter
          ((`notElem` damageTargets') . AssetTarget)
          healthDamageableAssets
      assignRestOfHealthDamage =
        InvestigatorDoAssignDamage
          investigatorId
          source
          DamageEvenly
          matcher
          (health - 1)
          0
      -- N.B. we have to add to the end of targets to handle the drop logic
      damageAsset aid =
        ComponentLabel
          (AssetComponent aid DamageToken)
          [ Msg.AssetDamageWithCheck aid source 1 0 False
          , assignRestOfHealthDamage (damageTargets <> [AssetTarget aid]) mempty
          ]
      damageInvestigator =
        ComponentLabel
          (InvestigatorComponent investigatorId DamageToken)
          [ Msg.InvestigatorDamage investigatorId source 1 0
          , assignRestOfHealthDamage
              (damageTargets <> [InvestigatorTarget investigatorId])
              mempty
          ]
      healthDamageMessages =
        [ damageInvestigator
        | InvestigatorTarget investigatorId `notElem` damageTargets'
        ]
          <> map damageAsset healthDamageableAssets'
    player <- getPlayer iid
    push $ chooseOne player healthDamageMessages
    pure a
  InvestigatorDoAssignDamage iid source DamageEvenly matcher 0 sanity damageTargets horrorTargets | iid == toId a -> do
    sanityDamageableAssets <-
      toList
        <$> getSanityDamageableAssets
          iid
          matcher
          sanity
          damageTargets
          horrorTargets
    mustBeDamagedFirstBeforeInvestigator <-
      select
        ( AssetCanBeAssignedHorrorBy iid
            <> AssetWithModifier NonDirectHorrorMustBeAssignToThisFirst
        )
    let
      getDamageTargets xs =
        if length xs >= length sanityDamageableAssets + 1
          then getDamageTargets (drop (length sanityDamageableAssets + 1) xs)
          else xs
      horrorTargets' = getDamageTargets horrorTargets
      sanityDamageableAssets' =
        filter
          ((`notElem` horrorTargets') . AssetTarget)
          sanityDamageableAssets
      assignRestOfSanityDamage =
        InvestigatorDoAssignDamage
          investigatorId
          source
          DamageEvenly
          matcher
          0
          (sanity - 1)
      -- N.B. we have to add to the end of targets to handle the drop logic
      damageAsset aid =
        ComponentLabel
          (AssetComponent aid HorrorToken)
          [ Msg.AssetDamageWithCheck aid source 0 1 False
          , assignRestOfSanityDamage mempty (horrorTargets <> [AssetTarget aid])
          ]
      damageInvestigator =
        ComponentLabel
          (InvestigatorComponent investigatorId HorrorToken)
          [ Msg.InvestigatorDamage investigatorId source 0 1
          , assignRestOfSanityDamage
              mempty
              (horrorTargets <> [InvestigatorTarget investigatorId])
          ]
      sanityDamageMessages =
        [ damageInvestigator
        | InvestigatorTarget investigatorId
            `notElem` horrorTargets'
            && null mustBeDamagedFirstBeforeInvestigator
        ]
          <> map damageAsset sanityDamageableAssets'
    player <- getPlayer iid
    push $ chooseOne player sanityDamageMessages
    pure a
  InvestigatorDoAssignDamage iid _ DamageEvenly _ _ _ _ _ | iid == investigatorId -> do
    error "DamageEvenly only works with just horror or just damage, but not both"
  InvestigatorDoAssignDamage iid source SingleTarget matcher health sanity damageTargets horrorTargets | iid == toId a -> do
    healthDamageableAssets <-
      getHealthDamageableAssets
        iid
        matcher
        health
        damageTargets
        horrorTargets
    sanityDamageableAssets <-
      getSanityDamageableAssets
        iid
        matcher
        sanity
        damageTargets
        horrorTargets
    let
      damageableAssets =
        toList $ healthDamageableAssets `union` sanityDamageableAssets
      continue h s t =
        InvestigatorDoAssignDamage
          iid
          source
          SingleTarget
          matcher
          (max 0 $ health - h)
          (max 0 $ sanity - s)
          (damageTargets <> [t | h > 0])
          (horrorTargets <> [t | s > 0])
      toAssetMessage (asset, (h, s)) =
        TargetLabel
          (AssetTarget asset)
          [ Msg.AssetDamageWithCheck asset source (min h health) (min s sanity) False
          , continue h s (AssetTarget asset)
          ]
    assetsWithCounts <- for damageableAssets $ \asset -> do
      health' <- fieldMap AssetRemainingHealth (fromMaybe 0) asset
      sanity' <- fieldMap AssetRemainingSanity (fromMaybe 0) asset
      pure (asset, (health', sanity'))

    player <- getPlayer iid
    push
      $ chooseOne player
      $ targetLabel
        a
        [ Msg.InvestigatorDamage investigatorId source health sanity
        , continue health sanity (toTarget a)
        ]
      : map toAssetMessage assetsWithCounts
    pure a
  InvestigatorDoAssignDamage iid source strategy matcher health sanity damageTargets horrorTargets | iid == toId a -> do
    healthDamageMessages <-
      if health > 0
        then do
          healthDamageableAssets <-
            toList <$> getHealthDamageableAssets iid matcher health damageTargets horrorTargets
          let
            assignRestOfHealthDamage =
              InvestigatorDoAssignDamage investigatorId source strategy matcher (health - 1) sanity
            damageAsset aid =
              ComponentLabel
                (AssetComponent aid DamageToken)
                [ Msg.AssetDamageWithCheck aid source 1 0 False
                , assignRestOfHealthDamage
                    (AssetTarget aid : damageTargets)
                    horrorTargets
                ]
            damageInvestigator =
              ComponentLabel
                (InvestigatorComponent investigatorId DamageToken)
                [ Msg.InvestigatorDamage investigatorId source 1 0
                , assignRestOfHealthDamage (toTarget investigatorId : damageTargets) horrorTargets
                ]
          case strategy of
            DamageAssetsFirst -> do
              pure
                $ [damageInvestigator | null healthDamageableAssets]
                <> map damageAsset healthDamageableAssets
            DamageAny ->
              pure $ damageInvestigator : map damageAsset healthDamageableAssets
            DamageFromHastur ->
              pure $ damageInvestigator : map damageAsset healthDamageableAssets
            DamageFirst def -> do
              validAssets <-
                List.intersect healthDamageableAssets
                  <$> select (matcher <> AssetControlledBy You <> assetIs def)
              pure
                $ if null validAssets
                  then damageInvestigator : map damageAsset healthDamageableAssets
                  else map damageAsset validAssets
            SingleTarget -> error "handled elsewhere"
            DamageEvenly -> error "handled elsewhere"
        else pure []
    sanityDamageMessages <-
      if sanity > 0
        then do
          sanityDamageableAssets <-
            toList
              <$> getSanityDamageableAssets iid matcher sanity damageTargets horrorTargets
          let
            assignRestOfSanityDamage =
              InvestigatorDoAssignDamage investigatorId source strategy matcher health (sanity - 1)
            damageInvestigator =
              ComponentLabel
                (InvestigatorComponent investigatorId HorrorToken)
                [ Msg.InvestigatorDamage investigatorId source 0 1
                , assignRestOfSanityDamage damageTargets (toTarget investigatorId : horrorTargets)
                ]
            damageAsset aid =
              ComponentLabel
                (AssetComponent aid HorrorToken)
                [ Msg.AssetDamageWithCheck aid source 0 1 False
                , assignRestOfSanityDamage damageTargets (toTarget aid : horrorTargets)
                ]
          case strategy of
            DamageAssetsFirst ->
              pure
                $ [damageInvestigator | null sanityDamageableAssets]
                <> map damageAsset sanityDamageableAssets
            DamageAny -> do
              mustBeDamagedFirstBeforeInvestigator <-
                select
                  ( AssetCanBeAssignedHorrorBy iid
                      <> AssetWithModifier NonDirectHorrorMustBeAssignToThisFirst
                  )
              pure
                $ [ damageInvestigator
                  | null mustBeDamagedFirstBeforeInvestigator
                  ]
                <> map damageAsset sanityDamageableAssets
            DamageFromHastur -> do
              mustBeDamagedFirstBeforeInvestigator <-
                select
                  ( AssetCanBeAssignedHorrorBy iid
                      <> AssetWithModifier NonDirectHorrorMustBeAssignToThisFirst
                  )
              pure
                $ [ damageInvestigator
                  | null mustBeDamagedFirstBeforeInvestigator
                  ]
                <> map damageAsset sanityDamageableAssets
            DamageFirst def -> do
              validAssets <-
                List.intersect sanityDamageableAssets
                  <$> select (matcher <> AssetControlledBy You <> assetIs def)
              pure
                $ if null validAssets
                  then damageInvestigator : map damageAsset sanityDamageableAssets
                  else map damageAsset validAssets
            SingleTarget -> error "handled elsewhere"
            DamageEvenly -> error "handled elsewhere"
        else pure []
    player <- getPlayer iid
    push $ chooseOne player $ healthDamageMessages <> sanityDamageMessages
    pure a
  Investigate investigation | investigation.investigator == investigatorId && investigation.isAction -> do
    (beforeWindowMsg, _, afterWindowMsg) <- frame (Window.PerformAction investigatorId #investigate)
    modifiers <- getModifiers @LocationId investigation.location
    modifiers' <- getModifiers a
    let
      investigateCost = foldr applyModifier 1 modifiers
      applyModifier (ActionCostOf (IsAction Action.Investigate) m) n = max 0 (n + m)
      applyModifier _ n = n
    pushAll
      $ [ BeginAction
        , beforeWindowMsg
        , TakeActions investigatorId [#investigate] (ActionCost investigateCost)
        ]
      <> [ CheckAttackOfOpportunity investigatorId False
         | ActionDoesNotCauseAttacksOfOpportunity #investigate `notElem` modifiers'
         ]
      <> [ toMessage $ investigation {investigateIsAction = False}
         , afterWindowMsg
         , FinishAction
         ]
    pure a
  InvestigatorDiscoverCluesAtTheirLocation iid source n maction | iid == investigatorId -> do
    mlid <- field InvestigatorLocation iid
    case mlid of
      Just lid -> runMessage (InvestigatorDiscoverClues iid lid source n maction) a
      _ -> pure a
  InvestigatorDiscoverClues iid lid source n _ | iid == investigatorId -> do
    canDiscoverClues <- getCanDiscoverClues iid lid
    when canDiscoverClues $ do
      checkWindowMsg <- checkWindows [mkWhen (Window.DiscoverClues iid lid source n)]
      pushAll [checkWindowMsg, Do msg]
    pure a
  Do (InvestigatorDiscoverClues iid lid source n maction) | iid == investigatorId -> do
    canDiscoverClues <- getCanDiscoverClues iid lid
    pushWhen canDiscoverClues $ DiscoverCluesAtLocation iid lid source n maction
    pure a
  GainClues iid source n | iid == investigatorId -> do
    window <- checkWindows ((`mkWindow` Window.GainsClues iid source n) <$> [#when, #after])
    pushAll [window, PlaceTokens source (toTarget iid) Clue n, After (GainClues iid source n)]
    pure a
  FlipClues target n | isTarget a target -> do
    pure $ a & tokensL %~ flipClues n
  DiscoverClues iid lid source n maction | iid == investigatorId -> do
    modifiers <- getModifiers lid
    let
      getMaybeMax :: ModifierType -> Maybe Int -> Maybe Int
      getMaybeMax (MaxCluesDiscovered x) Nothing = Just x
      getMaybeMax (MaxCluesDiscovered x) (Just x') = Just $ min x x'
      getMaybeMax _ x = x
      mMax :: Maybe Int = foldr getMaybeMax Nothing modifiers
      n' = maybe n (min n) mMax
    push $ Do $ DiscoverClues iid lid source n' maction
    pure a
  Do (DiscoverClues iid _ source n _) | iid == investigatorId -> do
    send $ format a <> " discovered " <> pluralize n "clue"
    push $ After $ GainClues iid source n
    pure $ a & tokensL %~ addTokens Clue n
  InvestigatorDiscardAllClues _ iid | iid == investigatorId -> do
    pure $ a & tokensL %~ removeAllTokens Clue
  MoveAllCluesTo source target | not (isTarget a target) -> do
    when (investigatorClues a > 0) (push $ PlaceTokens source target Clue $ investigatorClues a)
    pure $ a & tokensL %~ removeAllTokens Clue
  InitiatePlayCardAsChoose iid card choices msgs chosenCardStrategy windows' asAction | iid == toId a -> do
    event <- selectJust $ EventWithCardId $ toCardId card
    player <- getPlayer iid
    push
      $ chooseOne player
      $ [ targetLabel (toCardId choice)
          $ [ ReturnToHand iid (toTarget event)
            , InitiatePlayCardAs iid card choice msgs chosenCardStrategy windows' asAction
            ]
        | choice <- choices
        ]
    pure a
  InitiatePlayCardAs iid card choice msgs chosenCardStrategy windows' asAction | iid == toId a -> do
    let
      choiceDef = toCardDef choice
      choiceAsCard =
        (lookupPlayerCard choiceDef $ toCardId card)
          { pcOriginalCardCode = toCardCode card
          }
      chosenCardMsgs = case chosenCardStrategy of
        LeaveChosenCard -> []
        RemoveChosenCardFromGame -> [RemovePlayerCardFromGame True choice]

    pushAll
      $ chosenCardMsgs
      <> msgs
      <> [InitiatePlayCard iid (PlayerCard choiceAsCard) Nothing windows' asAction]
    pure $ a & handL %~ (PlayerCard choiceAsCard :) . filter (/= card)
  InitiatePlayCard iid card mtarget windows' asAction | iid == investigatorId ->
    do
      -- we need to check if the card is first an AsIfInHand card, if it is, then we let the owning entity handle this message
      modifiers' <- getModifiers (toTarget a)
      let
        shouldSkip = flip any modifiers' $ \case
          AsIfInHand card' -> card == card'
          _ -> False
      unless shouldSkip $ do
        afterPlayCard <- checkWindows [mkAfter (Window.PlayCard iid card)]
        if cdSkipPlayWindows (toCardDef card)
          then push $ PlayCard iid card mtarget windows' asAction
          else
            pushAll
              [ CheckWindow [iid] [mkWhen (Window.PlayCard iid card)]
              , PlayCard iid card mtarget windows' asAction
              , afterPlayCard
              ]
      pure a
  CardEnteredPlay iid card | iid == investigatorId -> do
    send $ format a <> " played " <> format card
    pure
      $ a
      & (handL %~ filter (/= card))
      & (discardL %~ filter ((/= card) . PlayerCard))
      & (deckL %~ Deck . filter ((/= card) . PlayerCard) . unDeck)
  ObtainCard card -> do
    pure
      $ a
      & (handL %~ filter (/= card))
      & (discardL %~ filter ((/= card) . PlayerCard))
      & (deckL %~ Deck . filter ((/= card) . PlayerCard) . unDeck)
  PutCampaignCardIntoPlay iid cardDef -> do
    let mcard = find ((== cardDef) . toCardDef) (unDeck investigatorDeck)
    case mcard of
      Nothing -> error "did not have campaign card"
      Just card -> push $ PutCardIntoPlay iid (PlayerCard card) Nothing []
    pure a
  InvestigatorPlayAsset iid aid | iid == investigatorId -> do
    -- It might seem weird that we remove the asset from the slots here since
    -- we haven't added it yet, however in the case that an asset adds some
    -- additional slot we'll have called RefillSlots already, and then this
    -- will have taken up the necessary slot so we remove it here so it can be
    -- placed correctly later
    pushAll [InvestigatorClearUnusedAssetSlots iid, Do (InvestigatorPlayAsset iid aid)]
    pure $ a & slotsL %~ removeFromSlots aid
  InvestigatorClearUnusedAssetSlots iid | iid == investigatorId -> do
    updatedSlots <- for (mapToList investigatorSlots) $ \(slotType, slots) -> do
      slots' <- for slots $ \slot -> do
        case slotItems slot of
          [] -> pure slot
          assets -> do
            ignored <- filterM (\aid -> hasModifier (AssetTarget aid) (DoNotTakeUpSlot slotType)) assets
            pure $ foldr removeIfMatches slot ignored
      pure (slotType, slots')
    pure $ a & slotsL .~ mapFromList updatedSlots
  Do (InvestigatorPlayAsset iid aid) | iid == investigatorId -> do
    -- this asset might already be slotted so check first
    fitsSlots <- fitsAvailableSlots aid a
    case fitsSlots of
      FitsSlots -> push (InvestigatorPlayedAsset iid aid)
      MissingSlots missingSlotTypes -> do
        assetsThatCanProvideSlots <-
          select
            $ assetControlledBy iid
            <> DiscardableAsset
            <> AssetOneOf (map AssetInSlot missingSlotTypes)

        -- N.B. This is explicitly for Empower Self and it's possible we don't want to do this without checking
        let assetsInSlotsOf aid' = nub $ concat $ filter (elem aid') $ map slotItems $ concat $ toList (a ^. slotsL)

        player <- getPlayer iid
        push
          $ if null assetsThatCanProvideSlots
            then InvestigatorPlayedAsset iid aid
            else
              chooseOne player
                $ [ targetLabel
                    aid'
                    $ map (toDiscardBy iid GameSource) assets
                    <> [ InvestigatorPlayAsset iid aid
                       ]
                  | aid' <- assetsThatCanProvideSlots
                  , let assets = assetsInSlotsOf aid'
                  ]
    pure a
  InvestigatorPlayedAsset iid aid | iid == investigatorId -> do
    slotTypes <- field AssetSlots aid
    assetCard <- field AssetCard aid

    canHoldMap :: Map SlotType [SlotType] <- do
      mods <- getModifiers a
      let
        canHold = \case
          SlotCanBe slotType canBeSlotType -> insertWith (<>) slotType [canBeSlotType]
          _ -> id
      pure $ foldr canHold mempty mods
    -- we need to figure out which slots are or aren't available
    -- we've claimed we can play this, but we might need to change the slotType
    let
      handleSlotType :: HasGame m => Map SlotType [Slot] -> SlotType -> m (Map SlotType [Slot])
      handleSlotType slots' sType = do
        available <- availableSlotTypesFor sType canHoldMap assetCard a
        case nub available of
          [] -> error "No slot found"
          [sType'] -> do
            slots'' <- placeInAvailableSlot aid assetCard (slots' ^. at sType' . non [])
            pure $ slots' & ix sType' .~ slots''
          xs | sType `elem` xs -> do
            slots'' <- placeInAvailableSlot aid assetCard (slots' ^. at sType . non [])
            pure $ slots' & ix sType .~ slots''
          _ -> error $ "Too many slots found, we expect at max two and one must be the original slot"

    slots <- foldM handleSlotType (a ^. slotsL) slotTypes

    pure $ a & handL %~ (filter (/= assetCard)) & slotsL .~ slots
  RemoveCampaignCard cardDef -> do
    pure
      $ a
      & (deckL %~ Deck . filter ((/= toCardCode cardDef) . toCardCode) . unDeck)
  RemoveAllCopiesOfCardFromGame iid cardCode | iid == investigatorId -> do
    assets <- select $ assetControlledBy iid
    for_ assets $ \assetId -> do
      cardCode' <- field AssetCardCode assetId
      when (cardCode == cardCode') (push $ RemoveFromGame (AssetTarget assetId))
    pure
      $ a
      & (deckL %~ Deck . filter ((/= cardCode) . toCardCode) . unDeck)
      & (discardL %~ filter ((/= cardCode) . toCardCode))
      & (handL %~ filter ((/= cardCode) . toCardCode))
  PutCardIntoPlay _ card _ _ -> do
    pure
      $ a
      & (deckL %~ Deck . filter ((/= card) . PlayerCard) . unDeck)
      & (discardL %~ filter ((/= card) . PlayerCard))
      & (handL %~ filter (/= card))
  Msg.InvestigatorDamage iid _ damage horror | iid == investigatorId -> do
    pure $ a & assignedHealthDamageL +~ damage & assignedSanityDamageL +~ horror
  DrivenInsane iid | iid == investigatorId -> do
    pure $ a & mentalTraumaL .~ investigatorSanity
  CheckDefeated source (isTarget a -> True) | not (a ^. defeatedL || a ^. resignedL) -> do
    facingDefeat <- getFacingDefeat a
    if facingDefeat
      then do
        modifiedHealth <- field InvestigatorHealth (toId a)
        modifiedSanity <- field InvestigatorSanity (toId a)
        let
          defeatedByHorror =
            investigatorSanityDamage a
              + investigatorAssignedSanityDamage
              >= modifiedSanity
          defeatedByDamage =
            investigatorHealthDamage a
              + investigatorAssignedHealthDamage
              >= modifiedHealth
          defeatedBy = case (defeatedByHorror, defeatedByDamage) of
            (True, True) -> DefeatedByDamageAndHorror source
            (True, False) -> DefeatedByHorror source
            (False, True) -> DefeatedByDamage source
            (False, False) -> DefeatedByOther source
        windowMsg <- checkWindows [mkWhen $ Window.InvestigatorWouldBeDefeated defeatedBy (toId a)]
        pushAll
          [ windowMsg
          , AssignDamage (InvestigatorTarget $ toId a)
          , InvestigatorWhenDefeated source investigatorId
          ]
      else push $ AssignDamage (InvestigatorTarget $ toId a)
    pure a
  AssignDamage target | isTarget a target -> do
    pure
      $ a
      & tokensL
      %~ ( addTokens Token.Damage investigatorAssignedHealthDamage
            . addTokens Horror investigatorAssignedSanityDamage
         )
      & (assignedHealthDamageL .~ 0)
      & (assignedSanityDamageL .~ 0)
  CancelAssignedDamage target damageReduction horrorReduction | isTarget a target -> do
    pure
      $ a
      & (assignedHealthDamageL %~ max 0 . subtract damageReduction)
      & (assignedSanityDamageL %~ max 0 . subtract horrorReduction)
  HealDamage (InvestigatorTarget iid) source amount | iid == investigatorId -> do
    afterWindow <- checkWindows [mkAfter $ Window.Healed DamageType (toTarget a) source amount]
    push afterWindow
    pure $ a & tokensL %~ subtractTokens Token.Damage amount
  HealHorrorWithAdditional (InvestigatorTarget iid) _ amount | iid == investigatorId -> do
    -- exists to have no callbacks, and to be resolved with AdditionalHealHorror
    cannotHealHorror <- hasModifier a CannotHealHorror
    if cannotHealHorror
      then pure a
      else do
        pure
          $ a
          & (tokensL %~ subtractTokens Horror amount)
          & (horrorHealedL .~ (min amount $ investigatorSanityDamage a))
  AdditionalHealHorror (InvestigatorTarget iid) source additional | iid == investigatorId -> do
    -- exists to have Callbacks for the total, get from investigatorHorrorHealed
    cannotHealHorror <- hasModifier a CannotHealHorror
    if cannotHealHorror
      then pure $ a & horrorHealedL .~ 0
      else do
        afterWindow <-
          checkWindows
            [ mkAfter
                $ Window.Healed HorrorType (toTarget a) source (investigatorHorrorHealed + additional)
            ]
        push afterWindow
        pure
          $ a
          & tokensL
          %~ subtractTokens Horror additional
          & horrorHealedL
          .~ 0
  HealHorror (InvestigatorTarget iid) source amount | iid == investigatorId -> do
    cannotHealHorror <- hasModifier a CannotHealHorror
    if cannotHealHorror
      then pure a
      else do
        afterWindow <- checkWindows [mkAfter $ Window.Healed #horror (toTarget a) source amount]
        push afterWindow
        pure $ a & tokensL %~ subtractTokens #horror amount
  MovedClues _ (isTarget a -> True) amount -> do
    pure $ a & tokensL %~ addTokens #clue amount
  MovedClues (isSource a -> True) _ amount -> do
    pure $ a & tokensL %~ subtractTokens #clue amount
  MovedHorror source (isTarget a -> True) amount -> do
    push $ checkDefeated source a
    pure $ a & tokensL %~ addTokens #horror amount
  MovedHorror (isSource a -> True) _ amount -> do
    pure $ a & tokensL %~ subtractTokens #horror amount
  MovedDamage source (isTarget a -> True) amount -> do
    push $ checkDefeated source a
    pure $ a & tokensL %~ addTokens #damage amount
  MovedDamage (isSource a -> True) _ amount -> do
    pure $ a & tokensL %~ subtractTokens #damage amount
  HealHorrorDirectly (InvestigatorTarget iid) _ amount | iid == investigatorId -> do
    -- USE ONLY WHEN NO CALLBACKS
    pure $ a & tokensL %~ subtractTokens #horror amount
  HealDamageDirectly (InvestigatorTarget iid) _ amount | iid == investigatorId -> do
    -- USE ONLY WHEN NO CALLBACKS
    pure $ a & tokensL %~ subtractTokens Token.Damage amount
  InvestigatorWhenDefeated source iid | iid == investigatorId -> do
    modifiedHealth <- field InvestigatorHealth (toId a)
    modifiedSanity <- field InvestigatorSanity (toId a)
    let
      defeatedByHorror = investigatorSanityDamage a >= modifiedSanity
      defeatedByDamage = investigatorHealthDamage a >= modifiedHealth
      defeatedBy = case (defeatedByHorror, defeatedByDamage) of
        (True, True) -> DefeatedByDamageAndHorror source
        (True, False) -> DefeatedByHorror source
        (False, True) -> DefeatedByDamage source
        (False, False) -> DefeatedByOther source
    windowMsg <- checkWindows [mkWhen $ Window.InvestigatorDefeated defeatedBy iid]
    pushAll [windowMsg, InvestigatorIsDefeated source iid]
    pure a
  InvestigatorKilled source iid | iid == investigatorId -> do
    unless investigatorDefeated $ do
      isLead <- (== iid) <$> getLeadInvestigatorId
      pushAll $ [ChooseLeadInvestigator | isLead] <> [Msg.InvestigatorDefeated source iid]
    pure $ a & defeatedL .~ True & endedTurnL .~ True
  MoveAllTo source lid | not (a ^. defeatedL || a ^. resignedL) -> do
    a <$ push (MoveTo $ move source investigatorId lid)
  MoveTo movement | isTarget a (moveTarget movement) -> do
    case moveDestination movement of
      ToLocationMatching matcher -> do
        lids <- select matcher
        player <- getPlayer investigatorId
        push
          $ chooseOrRunOne
            player
            [targetLabel lid [MoveTo $ movement {moveDestination = ToLocation lid}] | lid <- lids]
        pure a
      ToLocation lid -> do
        let iid = investigatorId

        moveWith <-
          select (InvestigatorWithModifier (CanMoveWith $ InvestigatorWithId iid) <> colocatedWith iid)
            >>= filterM (\iid' -> getCanMoveTo iid' (moveSource movement) lid)
            >>= traverse (traverseToSnd getPlayer)

        afterMoveButBeforeEnemyEngagement <-
          Helpers.checkWindows [mkAfter (Window.MovedButBeforeEnemyEngagement iid lid)]

        pushAll
          $ [ WhenWillEnterLocation iid lid
            , Do (WhenWillEnterLocation iid lid)
            , EnterLocation iid lid
            ]
          <> [ chooseOne
              player
              [ Label "Move too" [MoveTo $ move iid' iid' lid]
              , Label "Skip" []
              ]
             | (iid', player) <- moveWith
             ]
          <> [ afterMoveButBeforeEnemyEngagement
             , CheckEnemyEngagement iid
             ]
        pure a
  Do (WhenWillEnterLocation iid lid) | iid == investigatorId -> do
    pure $ a & locationL .~ lid
  CheckEnemyEngagement iid | iid == investigatorId -> do
    -- [AsIfAt]: enemies don't move to threat with AsIf, so we use actual location here
    -- This might not be correct and we should still check engagement and let
    -- that handle whether or not to move to threat area
    enemies <- select $ EnemyAt $ LocationWithId investigatorLocation
    a <$ pushAll [EnemyCheckEngagement eid | eid <- enemies]
  AddSlot iid slotType slot | iid == investigatorId -> do
    let
      slots = findWithDefault [] slotType investigatorSlots
      emptiedSlots = sort $ slot : map emptySlot slots
    push $ RefillSlots iid
    pure $ a & slotsL %~ insertMap slotType emptiedSlots
  RemoveSlot iid slotType | iid == investigatorId -> do
    -- This arbitrarily removes the first slot of the given type provided that
    -- it is granted by the investigator
    push $ RefillSlots iid
    pure $ a & slotsL . ix slotType %~ deleteFirstMatch (isSource a . slotSource)
  RefillSlots iid | iid == investigatorId -> do
    assetIds <- select $ AssetWithPlacement (InPlayArea iid)

    requirements <- concatForM assetIds $ \assetId -> do
      assetCard <- field AssetCard assetId
      mods <- getModifiers assetId
      let slotFilter sType = DoNotTakeUpSlot sType `notElem` mods
      pure $ (assetId,assetCard,) <$> filter slotFilter (cdSlots $ toCardDef assetCard)

    let allSlots :: [(SlotType, Slot)] = concatMap (\(k, vs) -> (k,) . emptySlot <$> vs) $ Map.assocs (a ^. slotsL)

    canHoldMap :: Map SlotType [SlotType] <- do
      mods <- getModifiers a
      let
        canHold = \case
          SlotCanBe slotType canBeSlotType -> insertWith (<>) slotType [canBeSlotType]
          _ -> id
      pure $ foldr canHold mempty mods

    let
      go [] _ = pure []
      go rs [] = pure $ map (\(_, _, sType) -> sType) rs
      go ((aid, card, slotType) : rs) slots = do
        (availableSlots1, unused1) <-
          partitionByM [canPutIntoSlot card . snd, pure . (== slotType) . fst] slots
        case sort availableSlots1 of
          [] -> case findWithDefault [] slotType canHoldMap of
            [] -> (slotType :) <$> go rs slots
            [other] -> do
              (availableSlots2, unused2) <-
                partitionByM [canPutIntoSlot card . snd, pure . (== other) . fst] slots
              case sort availableSlots2 of
                [] -> (slotType :) <$> go rs slots
                ((st, x) : rest) -> go rs ((st, putIntoSlot aid x) : rest <> unused2)
            _ -> error "not designed to work with more than one yet"
          ((st, x) : rest) -> go rs ((st, putIntoSlot aid x) : rest <> unused1)

    let
      fill :: HasGame m => [(AssetId, Card, SlotType)] -> Map SlotType [Slot] -> m (Map SlotType [Slot])
      fill [] slots = pure slots
      fill ((aid, card, slotType) : rs) slots = do
        (availableSlots1, unused1) <- partitionM (canPutIntoSlot card) (slots ^. at slotType . non [])
        case nonEmptySlotsFirst (sort availableSlots1) of
          [] -> case findWithDefault [] slotType canHoldMap of
            [] -> error "can't be filled 1"
            [other] -> do
              (availableSlots2, unused2) <- partitionM (canPutIntoSlot card) (slots ^. at other . non [])
              case nonEmptySlotsFirst (sort availableSlots2) of
                [] -> error "can't be filled 2"
                _ -> do
                  slots' <- placeInAvailableSlot aid card (slots ^. at other . non [])
                  fill rs (slots & ix other .~ slots' <> unused2)
            _ -> error "not designed to work with more than one yet"
          _ -> do
            slots' <- placeInAvailableSlot aid card (slots ^. at slotType . non [])
            fill rs (slots & ix slotType .~ slots' <> unused1)

    failedSlotTypes <- nub <$> go requirements allSlots

    let
      failedSlotTypes' = nub $ concatMap (\s -> s : findWithDefault [] s canHoldMap) failedSlotTypes
      failedAssetIds' = map (\(aid, _, _) -> aid) $ filter (\(_, _, s) -> s `elem` failedSlotTypes') requirements

    failedAssetIds <- selectFilter AssetCanLeavePlayByNormalMeans failedAssetIds'

    -- N.B. This is explicitly for Empower Self and it's possible we don't want to do this without checking
    let assetsInSlotsOf aid = nub $ concat $ filter (elem aid) $ map slotItems $ concat $ toList (a ^. slotsL)

    if null failedAssetIds
      then do
        slots' <- fill requirements (Map.map (map emptySlot) (a ^. slotsL))
        pure $ a & slotsL .~ slots'
      else do
        player <- getPlayer iid
        push
          $ chooseOne player
          $ [ targetLabel aid' $ map (toDiscardBy iid GameSource) assets <> [RefillSlots iid]
            | aid' <- failedAssetIds
            , let assets = assetsInSlotsOf aid'
            ]
        pure a
  ChooseEndTurn iid | iid == investigatorId -> pure $ a & endedTurnL .~ True
  Do BeginRound -> do
    actionsForTurn <- getAbilitiesForTurn a
    pure
      $ a
      & (endedTurnL .~ False)
      & (remainingActionsL .~ actionsForTurn)
      & (usedAdditionalActionsL .~ mempty)
      & (actionsTakenL .~ mempty)
      & (actionsPerformedL .~ mempty)
  DiscardTopOfDeck iid n source mTarget | iid == investigatorId -> do
    let (cs, deck') = draw n investigatorDeck
        (cs', essenceOfTheDreams) = partition ((/= "06113") . toCardCode) cs
    windowMsgs <-
      if null deck'
        then
          pure
            <$> checkWindows
              ((`mkWindow` Window.DeckHasNoCards iid) <$> [#when, #after])
        else pure []
    pushAll
      $ windowMsgs
      <> [DeckHasNoCards investigatorId mTarget | null deck']
      <> [ DiscardedTopOfDeck iid cs source target
         | target <- maybeToList mTarget
         ]
    pure
      $ a
      & deckL
      .~ deck'
      & discardL
      %~ (reverse cs' <>)
      & bondedCardsL
      <>~ map toCard essenceOfTheDreams
  DiscardUntilFirst iid' source (Deck.InvestigatorDeck iid) matcher | iid == investigatorId -> do
    (discards, remainingDeck) <- breakM (`extendedCardMatch` matcher) (unDeck investigatorDeck)
    let (discards', essenceOfTheDreams) = partition ((/= "06113") . toCardCode) discards
    case remainingDeck of
      [] -> do
        pushAll [RequestedPlayerCard iid' source Nothing discards, DeckHasNoCards iid Nothing]
        pure
          $ a
          & deckL
          .~ mempty
          & discardL
          %~ (reverse discards' <>)
          & bondedCardsL
          <>~ map toCard essenceOfTheDreams
      (x : xs) -> do
        push (RequestedPlayerCard iid' source (Just x) discards)
        pure
          $ a
          & deckL
          .~ Deck xs
          & discardL
          %~ (reverse discards <>)
          & bondedCardsL
          <>~ map toCard essenceOfTheDreams
  RevealUntilFirst iid source (Deck.InvestigatorDeck iid') matcher | iid == investigatorId && iid' == iid -> do
    (revealed, remainingDeck) <- breakM ((<=~> matcher) . toCard) (unDeck investigatorDeck)
    case remainingDeck of
      [] -> do
        pushAll
          [ RevealedCards iid source (Deck.InvestigatorDeck iid') Nothing (map PlayerCard revealed)
          , DeckHasNoCards iid Nothing
          ]
        pure $ a & deckL .~ mempty
      (x : xs) -> do
        push
          $ RevealedCards
            iid
            source
            (Deck.InvestigatorDeck iid')
            (Just $ PlayerCard x)
            (map PlayerCard revealed)
        pure $ a & deckL .~ Deck xs
  DrawCards cardDraw | cardDrawInvestigator cardDraw == toId a && cardDrawAction cardDraw -> do
    let
      iid = investigatorId
      source = cardDrawSource cardDraw
      n = cardDrawAmount cardDraw
    beforeWindowMsg <- checkWindows [mkWhen (Window.PerformAction iid #draw)]
    afterWindowMsg <- checkWindows [mkAfter (Window.PerformAction iid #draw)]
    drawing <- drawCards iid source n
    pushAll
      $ [ BeginAction
        , beforeWindowMsg
        , TakeActions iid [#draw] (ActionCost 1)
        , CheckAttackOfOpportunity iid False
        , drawing
        , afterWindowMsg
        , FinishAction
        ]
    pure a
  MoveTopOfDeckToBottom _ (Deck.InvestigatorDeck iid) n | iid == investigatorId -> do
    let (cards, deck) = draw n investigatorDeck
    pure $ a & deckL .~ Deck.withDeck (<> cards) deck
  DrawCards cardDraw | cardDrawInvestigator cardDraw == toId a && not (cardDrawAction cardDraw) -> do
    -- RULES: When a player draws two or more cards as the result of a single
    -- ability or game step, those cards are drawn simultaneously. If a deck
    -- empties middraw, reset the deck and complete the draw.

    -- RULES: If an investigator with an empty investigator deck needs to draw
    -- a card, that investigator shuffles his or her discard pile back into his
    -- or her deck, then draws the card, and upon completion of the entire draw
    -- takes one horror.

    let
      iid = investigatorId
      source = cardDrawSource cardDraw
      n = cardDrawAmount cardDraw

    modifiers' <- getModifiers (toTarget a)
    if null investigatorDeck
      then do
        -- What happens if the Yorick player has Graveyard Ghouls engaged
        -- with him or her and runs out of deck? "If an investigator with an
        -- empty investigator deck needs to draw a card, that investigator
        -- shuffles his or her discard pile back into his or her deck, then
        -- draws the card, and upon completion of the entire draw takes one
        -- horror. In this case, you cannot shuffle your discard pile into
        -- your deck, so you will neither draw 1 card, nor will you take 1
        -- horror."
        unless (null investigatorDiscard || CardsCannotLeaveYourDiscardPile `elem` modifiers') $ do
          drawing <- drawCards iid source n
          wouldDo
            (EmptyDeck iid (Just drawing))
            (Window.DeckWouldRunOutOfCards iid)
            (Window.DeckRanOutOfCards iid)
        -- push $ EmptyDeck iid
        pure a
      else do
        let deck = unDeck investigatorDeck
        if length deck < n
          then do
            drawing <- drawCards iid source (n - length deck)
            push drawing
            pure $ a & deckL .~ mempty & drawnCardsL %~ (<> deck)
          else do
            let
              (drawn, deck') = splitAt n deck
              allDrawn = investigatorDrawnCards <> drawn
              shuffleBackInEachWeakness =
                ShuffleBackInEachWeakness `elem` cardDrawRules cardDraw

              msgs = flip concatMap allDrawn $ \card ->
                case toCardType card of
                  PlayerTreacheryType ->
                    guard (not shuffleBackInEachWeakness)
                      *> [ DrewTreachery iid (Just $ Deck.InvestigatorDeck iid) (PlayerCard card)
                         , ResolvedCard iid (PlayerCard card)
                         ]
                  PlayerEnemyType -> do
                    guard $ not shuffleBackInEachWeakness
                    if hasRevelation card
                      then [Revelation iid $ PlayerCardSource card, ResolvedCard iid (PlayerCard card)]
                      else [DrewPlayerEnemy iid (PlayerCard card), ResolvedCard iid (PlayerCard card)]
                  other | hasRevelation card && other `notElem` [PlayerTreacheryType, PlayerEnemyType] -> do
                    guard $ ShuffleBackInEachWeakness `notElem` cardDrawRules cardDraw
                    [Revelation iid (PlayerCardSource card), ResolvedCard iid (PlayerCard card)]
                  _ -> []

            player <- getPlayer iid
            let
              weaknesses = map PlayerCard $ filter (`cardMatch` WeaknessCard) allDrawn
              msgs' =
                (<> msgs)
                  $ guard (shuffleBackInEachWeakness && notNull weaknesses)
                  *> [ FocusCards weaknesses
                     , chooseOne player
                        $ [ Label
                              "Shuffle Weaknesses back in"
                              [ UnfocusCards
                              , ShuffleCardsIntoDeck
                                  (Deck.InvestigatorDeck iid)
                                  weaknesses
                              ]
                          ]
                     ]

            windowMsgs <-
              if null deck'
                then pure <$> checkWindows ((`mkWindow` Window.DeckHasNoCards iid) <$> [#when, #after])
                else pure []
            (before, _, after) <- frame $ Window.DrawCards iid $ map toCard allDrawn
            checkHandSize <- hasModifier iid CheckHandSizeAfterDraw

            -- Cards with revelations won't be in hand afte they resolve, so exclude them from the discard
            let
              toDrawDiscard = \case
                AfterDrawDiscard x -> Sum x
                _ -> mempty
            let discardable =
                  filter (`cardMatch` (DiscardableCard <> NotCard CardWithRevelation)) allDrawn
            let discardAmount =
                  min (length discardable)
                    $ getSum (foldMap toDrawDiscard (toList $ cardDrawRules cardDraw))
            -- Only focus those that will still be in hand
            let focusable = map toCard $ filter (`cardMatch` NotCard CardWithRevelation) allDrawn

            pushAll
              $ windowMsgs
              <> [DeckHasNoCards iid Nothing | null deck']
              <> [InvestigatorDrewPlayerCard iid card | card <- allDrawn]
              <> [before]
              <> msgs'
              <> [after]
              <> ( guard (discardAmount > 0)
                    *> [ FocusCards focusable
                       , chooseN
                          player
                          discardAmount
                          [targetLabel (toCardId card) [DiscardCard iid (toSource a) (toCardId card)] | card <- discardable]
                       , UnfocusCards
                       ]
                 )
              <> [CheckHandSize iid | checkHandSize]
            pure $ a & handL %~ (<> map PlayerCard allDrawn) & deckL .~ Deck deck'
  InvestigatorDrewPlayerCard iid card -> do
    windowMsg <-
      checkWindows [mkAfter (Window.DrawCard iid (PlayerCard card) $ Deck.InvestigatorDeck iid)]
    push windowMsg
    pure a
  InvestigatorSpendClues iid n | iid == investigatorId -> do
    pure $ a & tokensL %~ subtractTokens Clue n
  SpendResources iid _ | iid == investigatorId -> do
    push $ Do msg
    pure a
  Do (SpendResources iid n) | iid == investigatorId -> do
    pure $ a & tokensL %~ subtractTokens Resource n
  LoseResources iid source n | iid == investigatorId -> do
    beforeWindowMsg <- checkWindows [mkWhen (Window.LostResources iid source n)]
    afterWindowMsg <- checkWindows [mkAfter (Window.LostResources iid source n)]
    pushAll [beforeWindowMsg, Do msg, afterWindowMsg]
    pure a
  Do (LoseResources iid _ n) | iid == investigatorId -> do
    pure $ a & tokensL %~ subtractTokens Resource n
  LoseAllResources iid | iid == investigatorId -> pure $ a & tokensL %~ removeAllTokens Resource
  TakeResources iid n source True | iid == investigatorId -> do
    beforeWindowMsg <- checkWindows [mkWhen (Window.PerformAction iid #resource)]
    afterWindowMsg <- checkWindows [mkAfter (Window.PerformAction iid #resource)]
    unlessM (hasModifier a CannotGainResources)
      $ pushAll
        [ BeginAction
        , beforeWindowMsg
        , TakeActions iid [#resource] (ActionCost 1)
        , CheckAttackOfOpportunity iid False
        , TakeResources iid n source False
        , afterWindowMsg
        , FinishAction
        ]
    pure a
  TakeResources iid n _ False | iid == investigatorId -> do
    cannotGainResources <- hasModifier a CannotGainResources
    pure $ if cannotGainResources then a else a & tokensL %~ addTokens Resource n
  PlaceTokens _ (isTarget a -> True) token n -> do
    pure $ a & tokensL %~ addTokens token n
  DoBatch _ (EmptyDeck iid mDrawing) | iid == investigatorId -> do
    pushAll
      $ [EmptyDeck iid mDrawing]
      <> maybeToList mDrawing
      <> [assignHorror iid EmptyDeckSource 1]
    pure a
  EmptyDeck iid _ | iid == investigatorId -> do
    modifiers' <- getModifiers (toTarget a)
    pushWhen (CardsCannotLeaveYourDiscardPile `notElem` modifiers')
      $ ShuffleDiscardBackIn iid
    pure a
  AllDrawCardAndResource | not (a ^. defeatedL || a ^. resignedL) -> do
    unlessM (hasModifier a CannotDrawCards) $ do
      mods <- getModifiers a
      let alternateUpkeepDraws = [target | AlternateUpkeepDraw target <- mods]
      if notNull alternateUpkeepDraws
        then do
          pid <- getPlayer investigatorId
          push
            $ chooseOrRunOne
              pid
              [targetLabel target [SendMessage target AllDrawCardAndResource] | target <- alternateUpkeepDraws]
        else pushM $ drawCards investigatorId ScenarioSource 1
    takeUpkeepResources a
  LoadDeck iid deck | iid == investigatorId -> do
    shuffled <- shuffleM $ flip map (unDeck deck) $ \card ->
      card {pcOwner = Just iid}
    pure $ a & deckL .~ Deck shuffled
  InvestigatorCommittedCard iid card | iid == investigatorId -> do
    commitedCardWindows <- Helpers.windows [Window.CommittedCard iid card]
    pushAll $ FocusCards [card] : commitedCardWindows <> [UnfocusCards]
    pure
      $ a
      & (handL %~ filter (/= card))
      & (deckL %~ Deck . filter ((/= card) . PlayerCard) . unDeck)
  PlaceUnderneath target cards | isTarget a target -> do
    update <-
      fmap appEndo
        $ foldMapM
          ( \card -> do
              mAssetId <- selectOne $ AssetWithCardId $ toCardId card
              pure
                $ Endo
                $ (slotsL %~ maybe id removeFromSlots mAssetId)
                . (deckL %~ Deck . filter ((/= card) . PlayerCard) . unDeck)
          )
          cards
    pure $ a & cardsUnderneathL <>~ cards & update
  PlaceUnderneath _ cards -> do
    update <-
      fmap (appEndo . mconcat)
        $ traverse
          ( \card -> do
              mAssetId <- selectOne $ AssetWithCardId $ toCardId card
              pure
                $ Endo
                $ (slotsL %~ maybe id removeFromSlots mAssetId)
                . (deckL %~ Deck . filter ((/= card) . PlayerCard) . unDeck)
                . (handL %~ filter (/= card))
          )
          cards
    pure $ a & update & foundCardsL %~ Map.map (filter (`notElem` cards))
  ChaosTokenCanceled iid _ token | iid == investigatorId -> do
    whenWindow <- checkWindows [mkWhen (Window.CancelChaosToken iid token)]
    afterWindow <- checkWindows [mkAfter (Window.CancelChaosToken iid token)]
    pushAll [whenWindow, afterWindow]
    pure a
  ChaosTokenIgnored iid _ token | iid == toId a -> do
    whenWindow <- checkWindows [mkWhen (Window.IgnoreChaosToken iid token)]
    afterWindow <- checkWindows [mkAfter (Window.IgnoreChaosToken iid token)]
    pushAll [whenWindow, afterWindow]
    pure a
  BeforeSkillTest skillTest | skillTestInvestigator skillTest == toId a -> do
    skillTestModifiers' <- getModifiers SkillTestTarget
    push
      $ if RevealChaosTokensBeforeCommittingCards `elem` skillTestModifiers'
        then StartSkillTest investigatorId
        else CommitToSkillTest skillTest $ StartSkillTestButton investigatorId
    pure a
  CommitToSkillTest skillTest triggerMessage' | skillTestInvestigator skillTest == toId a -> do
    let iid = skillTestInvestigator skillTest
    modifiers' <- getModifiers (toTarget a)
    committedCards <- field InvestigatorCommittedCards iid
    mustBeCommited <- filterM (`hasModifier` MustBeCommitted) committedCards
    allCommittedCards <- selectAgg id InvestigatorCommittedCards Anyone
    let
      skillDifficulty = skillTestDifficulty skillTest
      onlyCardComittedToTestCommitted =
        any
          (elem OnlyCardCommittedToTest . cdCommitRestrictions . toCardDef)
          allCommittedCards
      committedCardTitles = map toTitle allCommittedCards
    let window = mkWhen (Window.SkillTest $ skillTestType skillTest)
    actions <- getActions iid window
    isScenarioAbility <- getIsScenarioAbility
    mlid <- field InvestigatorLocation (toId a)
    clueCount <- maybe (pure 0) (field LocationClues) mlid
    skillIcons <- getSkillTestMatchingSkillIcons

    skillTestModifiers' <- getModifiers SkillTestTarget
    cannotCommitCards <-
      elem (CannotCommitCards AnyCard) <$> getModifiers (InvestigatorTarget investigatorId)
    committableCards <-
      if cannotCommitCards || onlyCardComittedToTestCommitted
        then pure []
        else do
          committableTreacheries <-
            filterM (field TreacheryCanBeCommitted)
              =<< select (treacheryInHandOf investigatorId)
          treacheryCards <- traverse (field TreacheryCard) committableTreacheries
          let asIfInHandForCommit = mapMaybe (preview _CanCommitToSkillTestsAsIfInHand) modifiers'
          flip filterM (asIfInHandForCommit <> investigatorHand <> treacheryCards) $ \case
            PlayerCard card -> do
              let
                passesCommitRestriction = \case
                  CommittableTreachery -> error "unhandled"
                  OnlyInvestigator matcher -> iid <=~> matcher
                  OnlyCardCommittedToTest -> pure $ null committedCardTitles
                  MaxOnePerTest -> pure $ toTitle card `notElem` committedCardTitles
                  OnlyYourTest -> pure True
                  MustBeCommittedToYourTest -> pure True
                  OnlyIfYourLocationHasClues -> pure $ clueCount > 0
                  OnlyTestWithActions as ->
                    pure $ maybe False (`elem` as) (skillTestAction skillTest)
                  ScenarioAbility -> pure isScenarioAbility
                  SelfCanCommitWhen matcher -> notNull <$> select (You <> matcher)
                  MinSkillTestValueDifference n ->
                    case skillTestType skillTest of
                      SkillSkillTest skillType -> do
                        baseValue <- baseSkillValueFor skillType Nothing [] (toId a)
                        pure $ (skillDifficulty - baseValue) >= n
                      AndSkillTest types -> do
                        baseValue <-
                          sum
                            <$> traverse (\skillType -> baseSkillValueFor skillType Nothing [] (toId a)) types
                        pure $ (skillDifficulty - baseValue) >= n
                      ResourceSkillTest ->
                        pure $ (skillDifficulty - investigatorResources a) >= n
                prevented = flip any modifiers' $ \case
                  CanOnlyUseCardsInRole role ->
                    null $ intersect (cdClassSymbols $ toCardDef card) (setFromList [Neutral, role])
                  CannotCommitCards matcher -> cardMatch card matcher
                  _ -> False
              passesCommitRestrictions <- allM passesCommitRestriction (cdCommitRestrictions $ toCardDef card)

              icons <- iconsForCard (toCard card)

              pure
                $ and
                  [ PlayerCard card `notElem` committedCards
                  , or
                      [ any (`member` skillIcons) icons
                      , and [null icons, toCardType card == SkillType]
                      ]
                  , passesCommitRestrictions
                  , not prevented
                  ]
            EncounterCard card ->
              pure $ CommittableTreachery `elem` (cdCommitRestrictions $ toCardDef card)
            VengeanceCard _ -> error "vengeance card"
    let
      mustCommit = any (any (== MustBeCommittedToYourTest) . cdCommitRestrictions . toCardDef) committableCards
      triggerMessage =
        [ triggerMessage'
        | CannotPerformSkillTest `notElem` skillTestModifiers' && not mustCommit
        ]
      beginMessage = CommitToSkillTest skillTest triggerMessage'
    player <- getPlayer iid
    if notNull committableCards || notNull committedCards || notNull actions
      then
        push
          $ SkillTestAsk
          $ chooseOne player
          $ map
            (\card -> targetLabel (toCardId card) [SkillTestCommitCard iid card, beginMessage])
            committableCards
          <> [ targetLabel (toCardId card) [SkillTestUncommitCard iid card, beginMessage]
             | card <- committedCards
             , card `notElem` mustBeCommited
             ]
          <> map
            (\action -> AbilityLabel iid action [window] [beginMessage])
            actions
          <> triggerMessage
      else
        pushWhen (notNull triggerMessage)
          $ SkillTestAsk
          $ chooseOne player triggerMessage
    pure a
  CommitToSkillTest skillTest triggerMessage | skillTestInvestigator skillTest /= investigatorId -> do
    let iid = skillTestInvestigator skillTest
    isPerlious <- getIsPerilous skillTest
    locationId <- getJustLocation iid
    isScenarioAbility <- getIsScenarioAbility
    clueCount <- field LocationClues locationId
    otherLocation <- field InvestigatorLocation (skillTestInvestigator skillTest)
    otherLocationOk <- maybe (pure False) (canCommitToAnotherLocation a) otherLocation
    allowedToCommit <- withoutModifier investigatorId CannotCommitToOtherInvestigatorsSkillTests
    lid <- field InvestigatorLocation (toId a)
    when (not isPerlious && allowedToCommit && (Just locationId == lid || otherLocationOk)) $ do
      committedCards <- field InvestigatorCommittedCards investigatorId
      allCommittedCards <- selectAgg id InvestigatorCommittedCards Anyone
      let
        skillDifficulty = skillTestDifficulty skillTest
        onlyCardComittedToTestCommitted =
          any
            ( elem OnlyCardCommittedToTest . cdCommitRestrictions . toCardDef
            )
            allCommittedCards
        committedCardTitles = map toTitle allCommittedCards
      modifiers' <- getModifiers (toTarget a)
      skillIcons <- getSkillTestMatchingSkillIcons
      let beginMessage = CommitToSkillTest skillTest triggerMessage
      committableCards <-
        if notNull committedCards || onlyCardComittedToTestCommitted
          then pure []
          else do
            committableTreacheries <-
              filterM (field TreacheryCanBeCommitted)
                =<< select (treacheryInHandOf investigatorId)
            treacheryCards <- traverse (field TreacheryCard) committableTreacheries
            let asIfInHandForCommit = mapMaybe (preview _CanCommitToSkillTestsAsIfInHand) modifiers'
            flip filterM (asIfInHandForCommit <> investigatorHand <> treacheryCards) $ \case
              PlayerCard card -> do
                let
                  passesCommitRestriction = \case
                    CommittableTreachery -> error "unhandled"
                    MaxOnePerTest -> pure $ toTitle card `notElem` committedCardTitles
                    OnlyInvestigator matcher -> iid <=~> matcher
                    OnlyCardCommittedToTest -> pure $ null committedCardTitles
                    OnlyYourTest -> pure False
                    MustBeCommittedToYourTest -> pure False
                    OnlyIfYourLocationHasClues -> pure $ clueCount > 0
                    OnlyTestWithActions as ->
                      pure $ maybe False (`elem` as) (skillTestAction skillTest)
                    ScenarioAbility -> pure isScenarioAbility
                    SelfCanCommitWhen matcher ->
                      notNull <$> select (You <> matcher)
                    MinSkillTestValueDifference n ->
                      case skillTestType skillTest of
                        SkillSkillTest skillType -> do
                          baseValue <- baseSkillValueFor skillType Nothing [] (toId a)
                          pure $ (skillDifficulty - baseValue) >= n
                        AndSkillTest types -> do
                          baseValue <-
                            sum
                              <$> traverse (\skillType -> baseSkillValueFor skillType Nothing [] (toId a)) types
                          pure $ (skillDifficulty - baseValue) >= n
                        ResourceSkillTest -> pure $ (skillDifficulty - investigatorResources a) >= n
                  prevented = flip any modifiers' $ \case
                    CanOnlyUseCardsInRole role ->
                      null $ intersect (cdClassSymbols $ toCardDef card) (setFromList [Neutral, role])
                    CannotCommitCards matcher -> cardMatch card matcher
                    _ -> False
                passesCriterias <- allM passesCommitRestriction (cdCommitRestrictions $ toCardDef card)
                icons <- iconsForCard (toCard card)
                pure
                  $ and
                    [ PlayerCard card `notElem` committedCards
                    , or
                        [ any (`member` skillIcons) icons
                        , and [null icons, toCardType card == SkillType]
                        ]
                    , passesCriterias
                    , not prevented
                    ]
              EncounterCard card ->
                pure $ CommittableTreachery `elem` (cdCommitRestrictions $ toCardDef card)
              VengeanceCard _ -> error "vengeance card"
      player <- getPlayer investigatorId
      pushWhen (notNull committableCards || notNull committedCards)
        $ SkillTestAsk
        $ chooseOne player
        $ map
          (\card -> targetLabel (toCardId card) [SkillTestCommitCard investigatorId card, beginMessage])
          committableCards
        <> map
          (\card -> targetLabel (toCardId card) [SkillTestUncommitCard investigatorId card, beginMessage])
          committedCards
    pure a
  CheckWindow iids windows | investigatorId `elem` iids -> do
    a <$ push (RunWindow investigatorId windows)
  RunWindow iid windows
    | iid == toId a
    , not (investigatorDefeated || investigatorResigned) || Window.hasEliminatedWindow windows -> do
        actions <- nub . concat <$> traverse (getActions iid) windows
        playableCards <- getPlayableCards a UnpaidCost windows
        runWindow a windows actions playableCards
        pure a
  SpendActions iid _ _ 0 | iid == investigatorId -> do
    pure a
  SpendActions iid source mAction n | iid == investigatorId -> do
    -- We want to try and spend the most restrictive action so we get any
    -- action that is not any additional action first, and if not that then the
    -- any additional action
    additionalActions <- getAdditionalActions a
    specificAdditionalActions <-
      filterM
        ( andM
            . sequence
              [ additionalActionCovers source (toList mAction)
              , pure . ((/= AnyAdditionalAction) . additionalActionType)
              ]
        )
        additionalActions
    let anyAdditionalActions = filter ((== AnyAdditionalAction) . additionalActionType) additionalActions

    case specificAdditionalActions of
      [] -> case anyAdditionalActions of
        [] -> pure $ a & remainingActionsL %~ max 0 . subtract n
        xs -> do
          player <- getPlayer iid
          push
            $ chooseOrRunOne player
            $ [ Label
                ("Use action from " <> lbl)
                [LoseAdditionalAction iid ac, SpendActions iid source mAction (n - 1)]
              | ac@(AdditionalAction lbl _ _) <- xs
              ]
          pure a
      xs -> do
        player <- getPlayer iid
        push
          $ chooseOrRunOne player
          $ [ Label
              ("Use action from " <> lbl)
              [LoseAdditionalAction iid ac, SpendActions iid source mAction (n - 1)]
            | ac@(AdditionalAction lbl _ _) <- xs
            ]
        pure a
  UseEffectAction iid eid _ | iid == investigatorId -> do
    additionalActions <- getAdditionalActions a
    let
      isEffectAction aAction = case additionalActionType aAction of
        EffectAction _ eid' -> eid == eid'
        _ -> False
    case find isEffectAction additionalActions of
      Nothing -> pure a
      Just aAction -> pure $ a & usedAdditionalActionsL %~ (aAction :)
  LoseActions iid source n | iid == investigatorId -> do
    beforeWindowMsg <- checkWindows [mkWhen $ Window.LostActions iid source n]
    afterWindowMsg <- checkWindows [mkAfter $ Window.LostActions iid source n]
    pushAll [beforeWindowMsg, Do msg, afterWindowMsg]
    pure a
  Do (LoseActions iid _source n) | iid == investigatorId -> do
    -- TODO: after losing all remaining actions we can lose additional actions
    additionalActions <- getAdditionalActions a
    let
      remaining = max 0 (n - a ^. remainingActionsL)
      additional = min remaining (length additionalActions)
      a' = a & remainingActionsL %~ max 0 . subtract n
    if additional > 0
      then
        if additional == length additionalActions
          then pure $ a' & usedAdditionalActionsL <>~ additionalActions
          else do
            player <- getPlayer iid
            push
              $ chooseN player additional
              $ [ Label ("Lose action from " <> lbl) [LoseAdditionalAction iid ac]
                | ac@(AdditionalAction lbl _ _) <- additionalActions
                ]
            pure a'
      else pure a'
  SetActions iid _ 0 | iid == investigatorId -> do
    additionalActions <- getAdditionalActions a
    pure $ a & remainingActionsL .~ 0 & usedAdditionalActionsL .~ additionalActions
  SetActions iid _ n | iid == investigatorId -> do
    pure $ a & remainingActionsL .~ n
  GainActions iid _ n | iid == investigatorId -> do
    -- TODO: If we add a window here we need to reconsider Ace of Rods, likely it would need a Do variant
    pure $ a & remainingActionsL +~ n
  LoseAdditionalAction iid n | iid == investigatorId -> do
    pure $ a & usedAdditionalActionsL %~ (n :)
  TakeActions iid actions cost | iid == investigatorId -> do
    pushAll
      $ [PayForAbility (abilityEffect a cost) []]
      <> [TakenActions iid actions | notNull actions]
    pure a
  TakenActions iid actions | iid == investigatorId -> do
    let previous = fromMaybe [] $ lastMay investigatorActionsPerformed
    let duplicated = actions `List.intersect` previous
    when (notNull duplicated)
      $ pushM
      $ checkWindows [mkAfter (Window.PerformedSameTypeOfAction iid duplicated)]

    pure $ a & actionsTakenL %~ (<> [actions]) & actionsPerformedL %~ (<> [actions])
  PerformedActions iid actions | iid == investigatorId -> do
    let previous = fromMaybe [] $ lastMay investigatorActionsPerformed
    let duplicated = actions `List.intersect` previous
    when (notNull duplicated)
      $ pushM
      $ checkWindows [mkAfter (Window.PerformedSameTypeOfAction iid duplicated)]
    pure $ a & actionsPerformedL %~ (<> [actions])
  PutCardOnTopOfDeck _ (Deck.InvestigatorDeck iid) card | iid == toId a -> do
    case card of
      PlayerCard pc ->
        pure
          $ a
          & (deckL %~ Deck . (pc :) . unDeck)
          & handL
          %~ filter (/= card)
          & discardL
          %~ filter (/= pc)
          & (foundCardsL . each %~ filter (/= PlayerCard pc))
      EncounterCard _ ->
        error "Can not put encounter card on top of investigator deck"
      VengeanceCard _ ->
        error "Can not put vengeance card on top of investigator deck"
  PutCardOnTopOfDeck _ _ card -> case card of
    PlayerCard pc ->
      pure
        $ a
        & (deckL %~ Deck . filter (/= pc) . unDeck)
        & handL
        %~ filter (/= card)
        & discardL
        %~ filter (/= pc)
        & (foundCardsL . each %~ filter (/= PlayerCard pc))
    EncounterCard _ -> pure $ a & handL %~ filter (/= card)
    VengeanceCard vcard -> pure $ a & handL %~ filter (/= vcard)
  PutCardOnBottomOfDeck _ (Deck.InvestigatorDeck iid) card | iid == toId a -> do
    case card of
      PlayerCard pc ->
        pure
          $ a
          & (deckL %~ Deck . (<> [pc]) . unDeck)
          & handL
          %~ filter (/= card)
          & discardL
          %~ filter (/= pc)
          & (foundCardsL . each %~ filter (/= PlayerCard pc))
      EncounterCard _ ->
        error "Can not put encounter card on bottom of investigator deck"
      VengeanceCard _ ->
        error "Can not put vengeance card on bottom of investigator deck"
  PutCardOnBottomOfDeck _ _ card -> case card of
    PlayerCard pc ->
      pure
        $ a
        & (deckL %~ Deck . filter (/= pc) . unDeck)
        & handL
        %~ filter (/= card)
        & discardL
        %~ filter (/= pc)
        & (foundCardsL . each %~ filter (/= PlayerCard pc))
    EncounterCard _ -> pure a
    VengeanceCard _ -> pure a
  AddToHand iid cards | iid == investigatorId -> do
    let
      choices = mapMaybe cardChoice cards
      cardChoice = \case
        card@(PlayerCard card') -> do
          if hasRevelation card'
            then
              if toCardType card' == PlayerTreacheryType
                then Just (card, DrewTreachery iid Nothing card)
                else Just (card, Revelation iid $ PlayerCardSource card')
            else
              if toCardType card' == PlayerEnemyType
                then Just (card, DrewPlayerEnemy iid card)
                else Nothing
        _ -> Nothing
    player <- getPlayer iid
    pushWhen (notNull choices)
      $ chooseOrRunOneAtATime player [targetLabel (toCardId card) [msg'] | (card, msg') <- choices]
    assetIds <- catMaybes <$> for cards (selectOne . AssetWithCardId . toCardId)
    pure
      $ a
      & (handL %~ (cards <>))
      & (cardsUnderneathL %~ filter (`notElem` cards))
      & (slotsL %~ flip (foldr removeFromSlots) assetIds)
      & (discardL %~ filter ((`notElem` cards) . PlayerCard))
      & (foundCardsL . each %~ filter (`notElem` cards))
      & (bondedCardsL %~ filter (`notElem` cards))
  ShuffleCardsIntoDeck (Deck.InvestigatorDeck iid) [] | iid == investigatorId -> do
    -- can't shuffle zero cards
    pure a
  ShuffleCardsIntoDeck (Deck.InvestigatorDeck iid) cards | iid == toId a -> do
    let (cards', essenceOfTheDreams) = partition ((/= "06113") . toCardCode) $ mapMaybe (preview _PlayerCard) cards
    deck <- shuffleM $ cards' <> filter (`notElem` cards') (unDeck investigatorDeck)
    pure
      $ a
      & deckL
      .~ Deck deck
      & handL
      %~ filter (`notElem` cards)
      & cardsUnderneathL
      %~ filter (`notElem` cards)
      & bondedCardsL
      %~ filter (`notElem` cards)
      & bondedCardsL
      <>~ map toCard essenceOfTheDreams
      & discardL
      %~ filter ((`notElem` cards) . PlayerCard)
      & (foundCardsL . each %~ filter (`notElem` cards))
  AddFocusedToHand _ (InvestigatorTarget iid') cardSource cardId | iid' == toId a -> do
    let
      card =
        fromJustNote "missing card"
          $ find ((== cardId) . toCardId) (findWithDefault [] cardSource $ a ^. foundCardsL)
      foundCards = a ^. foundCardsL & ix cardSource %~ filter (/= card)
    push $ addToHand iid' card
    pure $ a & foundCardsL .~ foundCards
  CommitCard _ card -> do
    pure $ a & foundCardsL . each %~ filter (/= card)
  AddFocusedToTopOfDeck _ (InvestigatorTarget iid') cardId | iid' == toId a -> do
    let
      card =
        fromJustNote "missing card"
          $ find ((== cardId) . toCardId) (concat $ toList $ a ^. foundCardsL)
          >>= toPlayerCard
      foundCards = Map.map (filter ((/= cardId) . toCardId)) $ a ^. foundCardsL
    push $ PutCardOnTopOfDeck iid' (Deck.InvestigatorDeck iid') (toCard card)
    pure $ a & foundCardsL .~ foundCards
  ShuffleAllFocusedIntoDeck _ (InvestigatorTarget iid') | iid' == investigatorId -> do
    let cards = findWithDefault [] Zone.FromDeck $ a ^. foundCardsL
    push $ ShuffleCardsIntoDeck (Deck.InvestigatorDeck iid') cards
    pure $ a & foundCardsL %~ deleteMap Zone.FromDeck
  PutAllFocusedIntoDiscard _ (InvestigatorTarget iid') | iid' == investigatorId -> do
    let cards = onlyPlayerCards $ findWithDefault [] Zone.FromDiscard $ a ^. foundCardsL
    let (cards', essenceOfTheDreams) = partition ((/= "06113") . toCardCode) cards
    pure
      $ a
      & foundCardsL
      %~ deleteMap Zone.FromDiscard
      & discardL
      <>~ cards'
      & bondedCardsL
      <>~ map toCard essenceOfTheDreams
  EndSearch iid _ (InvestigatorTarget iid') cardSources | iid == investigatorId -> do
    push (SearchEnded iid)
    let
      foundKey = \case
        Zone.FromTopOfDeck _ -> Zone.FromDeck
        Zone.FromBottomOfDeck _ -> Zone.FromDeck
        other -> other
    player <- getPlayer iid
    for_ cardSources $ \(cardSource, returnStrategy) -> case returnStrategy of
      DiscardRest -> do
        push
          $ chooseOneAtATime player
          $ map
            ( \case
                PlayerCard c -> targetLabel (toCardId c) [AddToDiscard iid c]
                EncounterCard c -> targetLabel (toCardId c) [AddToEncounterDiscard c]
                VengeanceCard _ -> error "not possible"
            )
            (findWithDefault [] Zone.FromDeck $ a ^. foundCardsL)
      PutBackInAnyOrder -> do
        when (foundKey cardSource /= Zone.FromDeck) (error "Expects a deck")
        push
          $ chooseOneAtATime player
          $ mapTargetLabelWith
            toCardId
            (\c -> [AddFocusedToTopOfDeck iid (toTarget iid') (toCardId c)])
            (findWithDefault [] Zone.FromDeck $ a ^. foundCardsL)
      ShuffleBackIn -> do
        when (foundKey cardSource /= Zone.FromDeck) (error "Expects a deck")
        pushWhen (notNull $ a ^. foundCardsL)
          $ ShuffleCardsIntoDeck
            (Deck.InvestigatorDeck iid)
            (findWithDefault [] Zone.FromDeck $ a ^. foundCardsL)
      PutBack -> when (foundKey cardSource == Zone.FromDeck) (error "Can not take deck")
      RemoveRestFromGame -> do
        -- Try to obtain, then don't add back
        pushAll $ map ObtainCard $ findWithDefault [] Zone.FromDeck (a ^. foundCardsL)
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            case abilityLimitType (abilityLimit usedAbility) of
              Just (PerSearch _) -> False
              _ -> True
        )
  EndSearch iid _ _ _ | iid == investigatorId -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            case abilityLimitType (abilityLimit usedAbility) of
              Just (PerSearch _) -> False
              _ -> True
        )
  SearchEnded iid | iid == investigatorId -> pure $ a & searchL .~ Nothing
  CancelSearch iid | iid == investigatorId -> do
    let zoneCards = mapToList (a ^. foundCardsL)
    updates <- fmap (appEndo . mconcat) $ for zoneCards $ \(zone, cards) -> case zone of
      Zone.FromDeck -> do
        deck' <- Deck <$> shuffleM (unDeck investigatorDeck <> onlyPlayerCards cards)
        pure $ Endo $ deckL .~ deck'
      _ -> error "Unhandled zone, this was added for Shocking Discovery only which is FromDeck"
    pure $ a & searchL .~ Nothing & updates
  Search searchType iid _ (InvestigatorTarget iid') _ _ _ | iid' == toId a -> do
    if searchType == Searching
      then
        wouldDo
          msg
          (Window.WouldSearchDeck iid (Deck.InvestigatorDeck iid'))
          (Window.SearchedDeck iid (Deck.InvestigatorDeck iid'))
      else do
        batchId <- getRandom
        push $ DoBatch batchId msg

    pure a
  DoBatch
    batchId
    (Search searchType iid source target@(InvestigatorTarget iid') cardSources cardMatcher foundStrategy) | iid' == toId a -> do
      mods <- getModifiers iid
      let
        additionalDepth = foldl' (+) 0 $ mapMaybe (preview Modifier._SearchDepth) mods
        foundCards :: Map Zone [Card] =
          foldl'
            ( \hmap (cardSource, _) -> case cardSource of
                Zone.FromDeck ->
                  insertWith (<>) Zone.FromDeck (map PlayerCard $ unDeck investigatorDeck) hmap
                Zone.FromTopOfDeck n ->
                  insertWith
                    (<>)
                    Zone.FromDeck
                    (map PlayerCard . take (n + additionalDepth) $ unDeck investigatorDeck)
                    hmap
                Zone.FromBottomOfDeck n ->
                  insertWith
                    (<>)
                    Zone.FromDeck
                    (map PlayerCard . take (n + additionalDepth) . reverse $ unDeck investigatorDeck)
                    hmap
                Zone.FromDiscard ->
                  insertWith (<>) Zone.FromDiscard (map PlayerCard investigatorDiscard) hmap
                other -> error $ mconcat ["Zone ", show other, " not yet handled"]
            )
            mempty
            cardSources
        deck =
          filter
            ((`notElem` findWithDefault [] Zone.FromDeck foundCards) . PlayerCard)
            (unDeck investigatorDeck)
      pushBatch batchId $ EndSearch iid source target cardSources
      pushBatch batchId $ ResolveSearch iid

      when (searchType == Searching) $ do
        pushBatch batchId
          $ CheckWindow [iid] [Window #when (Window.AmongSearchedCards batchId iid) (Just batchId)]

      pure
        $ a
        & searchL
        ?~ InvestigatorSearch searchType iid source target cardSources cardMatcher foundStrategy foundCards
        & deckL
        .~ Deck deck
  ResolveSearch iid | iid == investigatorId -> do
    case investigatorSearch of
      Just
        (InvestigatorSearch _ _ source (InvestigatorTarget iid') _ cardMatcher foundStrategy foundCards) -> do
          mods <- getModifiers iid
          let
            applyMod (AdditionalTargets n) = over biplate (+ n)
            applyMod _ = id
            foundStrategy' = foldr applyMod foundStrategy mods
            targetCards = Map.map (filter (`cardMatch` cardMatcher)) foundCards

          player <- getPlayer iid
          case foundStrategy' of
            DrawOrPlayFound who n -> do
              let windows' = [mkWhen Window.NonFast, mkWhen (Window.DuringTurn iid)]
              playableCards <- concatForM (mapToList targetCards) $ \(_, cards) ->
                filterM (getIsPlayable who source UnpaidCost windows') cards
              let
                choices =
                  [ targetLabel
                    (toCardId card)
                    [ if card `elem` playableCards
                        then
                          chooseOne
                            player
                            [ Label "Add to hand" [addFoundToHand]
                            , Label "Play Card" [addFoundToHand, PayCardCost iid card windows']
                            ]
                        else addFoundToHand
                    ]
                  | (zone, cards) <- mapToList targetCards
                  , card <- cards
                  , let addFoundToHand = AddFocusedToHand iid (toTarget who) zone (toCardId card)
                  ]
              push
                $ if null choices
                  then chooseOne player [Label "No cards found" []]
                  else chooseN player (min n (length choices)) choices
            DrawOrCommitFound who n -> do
              -- [TODO] We need this to determine what state the skill test
              -- is in, if we are committing cards we need to use
              -- SkillTestCommitCard instead of CommitCard
              committable <- filterM (getIsCommittable who) $ concatMap snd $ mapToList targetCards
              let
                choices =
                  [ targetLabel
                    (toCardId card)
                    [ if card `elem` committable
                        then
                          chooseOne
                            player
                            [Label "Add to hand" [addFoundToHand], Label "Commit to skill test" [CommitCard who card]]
                        else addFoundToHand
                    ]
                  | (zone, cards) <- mapToList targetCards
                  , card <- cards
                  , let addFoundToHand = AddFocusedToHand iid (toTarget who) zone (toCardId card)
                  ]
              push
                $ if null choices
                  then chooseOne player [Label "No cards found" []]
                  else chooseN player (min n (length choices)) choices
            RemoveFoundFromGame _ n -> do
              let
                choices =
                  [ targetLabel (toCardId card) [RemovePlayerCardFromGame False card]
                  | (_, cards) <- mapToList targetCards
                  , card <- cards
                  ]
              push
                $ if null choices
                  then chooseOne player [Label "No cards found" []]
                  else chooseN player (min n (length choices)) choices
            DrawFound who n -> do
              let
                choices =
                  [ targetLabel (toCardId card) [AddFocusedToHand iid (toTarget who) zone (toCardId card)]
                  | (zone, cards) <- mapToList targetCards
                  , card <- cards
                  ]
              push
                $ if null choices
                  then chooseOne player [Label "No cards found" []]
                  else chooseN player (min n (length choices)) choices
            DrawFoundUpTo who n -> do
              let
                choices =
                  [ targetLabel (toCardId card) [AddFocusedToHand iid (toTarget who) zone (toCardId card)]
                  | (zone, cards) <- mapToList targetCards
                  , card <- cards
                  ]
              push
                $ if null choices
                  then chooseOne player [Label "No cards found" []]
                  else chooseUpToN player n "Do not draw more cards" choices
            PlayFound who n -> do
              let windows' = [mkWhen Window.NonFast, mkWhen (Window.DuringTurn iid)]
              playableCards <- for (mapToList targetCards) $ \(zone, cards) -> do
                cards' <- filterM (getIsPlayable who source UnpaidCost windows') cards
                pure (zone, cards')
              let
                choices =
                  [ targetLabel (toCardId card) [addToHand who card, PayCardCost iid card windows']
                  | (_, cards) <- playableCards
                  , card <- cards
                  ]
              push $ chooseN player n $ if null choices then [Label "No cards found" []] else choices
            PlayFoundNoCost who n -> do
              let windows' = [mkWhen Window.NonFast, mkWhen (Window.DuringTurn iid)]
              playableCards <- for (mapToList targetCards) $ \(zone, cards) -> do
                cards' <- filterM (getIsPlayable who source Cost.PaidCost windows') cards
                pure (zone, cards')
              let
                choices =
                  [ targetLabel (toCardId card)
                    $ [addToHand who card, PutCardIntoPlay iid card Nothing windows']
                  | (_, cards) <- playableCards
                  , card <- cards
                  ]
              push $ chooseN player n $ if null choices then [Label "No cards found" []] else choices
            DeferSearchedToTarget searchTarget -> do
              -- N.B. You must handle target duplication (see Mandy Thompson) yourself
              push
                $ if null targetCards
                  then chooseOne player [Label "No cards found" [SearchNoneFound iid searchTarget]]
                  else SearchFound iid searchTarget (Deck.InvestigatorDeck iid') (concat $ toList targetCards)
            DrawAllFound who -> do
              let
                choices =
                  [ targetLabel (toCardId card) [AddFocusedToHand iid (toTarget who) zone (toCardId card)]
                  | (zone, cards) <- mapToList targetCards
                  , card <- cards
                  ]
              push
                $ if null choices
                  then chooseOne player [Label "No cards found" []]
                  else chooseOneAtATime player choices
            ReturnCards -> pure ()
      _ -> pure ()
    pure a
  RemoveFromDiscard iid cardId | iid == investigatorId -> do
    pure $ a & discardL %~ filter ((/= cardId) . toCardId)
  PlaceInBonded iid card | iid == investigatorId -> do
    pure
      $ a
      & bondedCardsL
      %~ nub
      . (card :)
      & handL
      %~ filter (/= card)
      & discardL
      %~ filter ((/= card) . toCard)
      & deckL
      %~ filter ((/= card) . toCard)
      & (foundCardsL . each %~ filter (/= card))
      & cardsUnderneathL
      %~ filter (/= card)
      & decksL
      . each
      %~ filter (/= card)
  SufferTrauma iid physical mental | iid == investigatorId -> do
    push $ CheckTrauma iid
    pure $ a & physicalTraumaL +~ physical & mentalTraumaL +~ mental
  CheckTrauma iid | iid == investigatorId -> do
    pushWhen (investigatorPhysicalTrauma >= investigatorHealth)
      $ InvestigatorKilled (toSource a) iid
    pushWhen (investigatorMentalTrauma >= investigatorSanity)
      $ DrivenInsane iid
    pure a
  HealTrauma iid physical mental | iid == investigatorId -> do
    pure
      $ a
      & (physicalTraumaL %~ max 0 . subtract physical)
      & (mentalTraumaL %~ max 0 . subtract mental)
  GainXP iid _ amount | iid == investigatorId -> pure $ a & xpL +~ amount
  SpendXP iid amount | iid == investigatorId -> do
    pure $ a & xpL %~ max 0 . subtract amount
  InvestigatorPlaceCluesOnLocation iid source n | iid == investigatorId -> do
    -- [AsIfAt] assuming as if is still in effect
    mlid <- field InvestigatorLocation iid
    let cluesToPlace = min n (investigatorClues a)
    for_ mlid $ \lid ->
      push $ PlaceTokens source (LocationTarget lid) Clue cluesToPlace
    pure $ a & tokensL %~ subtractTokens Clue cluesToPlace
  InvestigatorPlaceAllCluesOnLocation iid source | iid == investigatorId -> do
    -- [AsIfAt] assuming as if is still in effect
    mlid <- field InvestigatorLocation iid
    for_ mlid $ \lid ->
      push $ PlaceTokens source (LocationTarget lid) Clue (investigatorClues a)
    pure $ a & tokensL %~ removeAllTokens Clue
  RemoveFromBearersDeckOrDiscard card -> do
    if pcOwner card == Just investigatorId
      then pure $ a & (discardL %~ filter (/= card)) & (deckL %~ Deck . filter (/= card) . unDeck)
      else pure a
  RemovePlayerCardFromGame addToRemovedFromGame card -> do
    when addToRemovedFromGame $ push $ RemovedFromGame card
    case preview _PlayerCard card of
      Just pc ->
        pure
          $ a
          & discardL
          %~ filter (/= pc)
          & handL
          %~ filter (/= card)
          & (deckL %~ Deck . filter (/= pc) . unDeck)
          & foundCardsL
          . each
          %~ filter (/= card)
      Nothing ->
        -- encounter cards can only be in hand
        pure $ a & (handL %~ filter (/= card))
  RemoveDiscardFromGame iid | iid == investigatorId -> do
    pushAll $ map (RemovedFromGame . PlayerCard) investigatorDiscard
    pure $ a & discardL .~ []
  After (FailedSkillTest iid mAction _ (InvestigatorTarget iid') _ n) | iid == iid' && iid == toId a -> do
    mTarget <- getSkillTestTarget
    mCurrentLocation <- field InvestigatorLocation iid
    let
      windows = do
        Action.Investigate <- maybeToList mAction
        case mTarget of
          Just (LocationTarget lid) ->
            [ mkWhen $ Window.FailInvestigationSkillTest iid lid n
            , mkAfter $ Window.FailInvestigationSkillTest iid lid n
            ]
          _ -> case mCurrentLocation of
            Just currentLocation ->
              [ mkWhen $ Window.FailInvestigationSkillTest iid currentLocation n
              , mkAfter $ Window.FailInvestigationSkillTest iid currentLocation n
              ]
            _ -> []
    pushM
      $ checkWindows
      $ mkWhen (Window.FailSkillTest iid n)
      : mkAfter (Window.FailSkillTest iid n)
      : windows
    pure a
  When (PassedSkillTest iid mAction source (InvestigatorTarget iid') _ n) | iid == iid' && iid == toId a -> do
    mTarget <- getSkillTestTarget
    let
      windows = do
        Action.Investigate <- maybeToList mAction
        case mTarget of
          Just (ProxyTarget (LocationTarget lid) _) -> do
            [mkWhen $ Window.PassInvestigationSkillTest iid lid n]
          Just (LocationTarget lid) -> do
            [mkWhen $ Window.PassInvestigationSkillTest iid lid n]
          Just (BothTarget (LocationTarget lid1) (LocationTarget lid2)) ->
            [ mkWhen $ Window.PassInvestigationSkillTest iid lid1 n
            , mkWhen $ Window.PassInvestigationSkillTest iid lid2 n
            ]
          _ -> error "expecting location source for investigate"
    pushM $ checkWindows $ mkWhen (Window.PassSkillTest mAction source iid n) : windows
    pure a
  After (PassedSkillTest iid mAction source (InvestigatorTarget iid') _ n) | iid == iid' && iid == toId a -> do
    mTarget <- getSkillTestTarget
    let
      windows = do
        Action.Investigate <- maybeToList mAction
        case mTarget of
          Just (ProxyTarget (LocationTarget lid) _) -> do
            [mkAfter $ Window.PassInvestigationSkillTest iid lid n]
          Just (LocationTarget lid) -> do
            [mkAfter $ Window.PassInvestigationSkillTest iid lid n]
          Just (BothTarget (LocationTarget lid1) (LocationTarget lid2)) ->
            [ mkAfter $ Window.PassInvestigationSkillTest iid lid1 n
            , mkAfter $ Window.PassInvestigationSkillTest iid lid2 n
            ]
          _ -> error "expecting location source for investigate"
    pushM $ checkWindows $ mkAfter (Window.PassSkillTest mAction source iid n) : windows
    pure a
  PlayerWindow iid additionalActions isAdditional | iid == investigatorId -> do
    let
      windows = [mkWhen (Window.DuringTurn iid), mkWhen Window.FastPlayerWindow, mkWhen Window.NonFast]
    actions <- nub <$> concatMapM (getActions iid) windows
    anyForced <- anyM (isForcedAbility iid) actions
    if anyForced
      then do
        -- Silent forced abilities should trigger automatically
        let
          (silent, normal) = partition isSilentForcedAbility actions
          toForcedAbilities = map (($ windows) . UseAbility iid)
          toUseAbilities = map ((\f -> f windows []) . AbilityLabel iid)
        player <- getPlayer iid
        pushAll
          $ toForcedAbilities silent
          <> [chooseOne player (toUseAbilities normal) | notNull normal]
          <> [PlayerWindow iid additionalActions isAdditional]
      else do
        modifiers <- getModifiers (InvestigatorTarget iid)
        canAffordTakeResources <- getCanAfford a [#resource]
        canAffordDrawCards <- getCanAfford a [#draw]
        additionalActions' <- getAdditionalActions a
        let
          usesAction = not isAdditional
          drawCardsF = if usesAction then drawCardsAction else drawCards
          effectActions = flip mapMaybe additionalActions' $ \case
            AdditionalAction _ _ (EffectAction tooltip effectId) ->
              Just
                $ EffectActionButton
                  (Tooltip tooltip)
                  effectId
                  [UseEffectAction iid effectId windows]
            _ -> Nothing

        playableCards <- getPlayableCards a UnpaidCost windows
        drawing <- drawCardsF iid a 1

        canDraw <- canDo iid #draw
        canTakeResource <- canDo iid #resource
        canPlay <- canDo iid #play
        player <- getPlayer iid

        push
          $ AskPlayer
          $ chooseOne player
          $ nub
          $ additionalActions
          <> [ ComponentLabel (InvestigatorComponent iid ResourceToken)
              $ [TakeResources iid 1 (toSource a) usesAction]
             | canAffordTakeResources && CannotGainResources `notElem` modifiers && canTakeResource
             ]
          <> [ ComponentLabel (InvestigatorDeckComponent iid) [drawing]
             | canAffordDrawCards
             , canDraw
             , none (`elem` modifiers) [CannotDrawCards, CannotManipulateDeck]
             ]
          <> [ targetLabel (toCardId c) [InitiatePlayCard iid c Nothing windows usesAction]
             | canPlay
             , c <- playableCards
             ]
          <> [EndTurnButton iid [ChooseEndTurn iid]]
          <> map ((\f -> f windows []) . AbilityLabel iid) actions
          <> effectActions
    pure a
  PlayerWindow iid additionalActions isAdditional | iid /= investigatorId -> do
    let windows = [mkWhen (Window.DuringTurn iid), mkWhen Window.FastPlayerWindow]
    actions <- nub <$> concatMapM (getActions investigatorId) windows
    anyForced <- anyM (isForcedAbility investigatorId) actions
    unless anyForced $ do
      playableCards <- getPlayableCards a UnpaidCost windows
      let
        usesAction = not isAdditional
        choices =
          additionalActions
            <> [ targetLabel (toCardId c)
                $ [InitiatePlayCard investigatorId c Nothing windows usesAction]
               | c <- playableCards
               ]
            <> map ((\f -> f windows []) . AbilityLabel investigatorId) actions
      player <- getPlayer investigatorId
      unless (null choices)
        $ push
        $ AskPlayer
        $ chooseOne player choices
    pure a
  EndInvestigation -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            abilityLimitType (abilityLimit usedAbility) /= Just PerPhase
        )
  EndEnemy -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            abilityLimitType (abilityLimit usedAbility) /= Just PerPhase
        )
  ScenarioCountIncrementBy CurrentDepth n | n > 0 -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            abilityLimitType (abilityLimit usedAbility) /= Just PerDepthLevel
        )
  EndUpkeep -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            abilityLimitType (abilityLimit usedAbility) /= Just PerPhase
        )
  EndMythos -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            abilityLimitType (abilityLimit usedAbility) /= Just PerPhase
        )
  EndRound -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            abilityLimitType (abilityLimit usedAbility) /= Just PerRound
        )
      & usedAdditionalActionsL
      .~ mempty
  EndTurn iid | iid == toId a -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter
        ( \UsedAbility {..} ->
            abilityLimitType (abilityLimit usedAbility) /= Just PerTurn
        )
  UseCardAbility iid (isSource a -> True) 500 _ _ -> do
    otherInvestigators <-
      select $ colocatedWith investigatorId <> NotInvestigator (InvestigatorWithId investigatorId)
    case nonEmpty otherInvestigators of
      Nothing -> error "No other investigators"
      Just (x :| xs) -> do
        player <- getPlayer iid
        push
          $ chooseOrRunOne player
          $ [ targetLabel iid'
              $ [ chooseSome1 player "Done giving keys"
                    $ [Label ("Give " <> keyName k <> " key") [PlaceKey (toTarget iid') k] | k <- toList investigatorKeys]
                ]
            | iid' <- x : xs
            ]
    pure a
  UseAbility iid ability windows | iid == investigatorId -> do
    activeInvestigator <- getActiveInvestigatorId
    mayIgnoreLocationEffectsAndKeywords <- hasModifier iid MayIgnoreLocationEffectsAndKeywords
    let
      mayIgnore =
        case abilitySource ability of
          LocationSource _ -> mayIgnoreLocationEffectsAndKeywords
          _ -> False
      resolveAbility =
        [SetActiveInvestigator iid | iid /= activeInvestigator]
          <> [PayForAbility ability windows, ResolvedAbility ability]
          <> [SetActiveInvestigator activeInvestigator | iid /= activeInvestigator]
    player <- getPlayer iid

    if mayIgnore
      then push $ chooseOne player [Label "Ignore effect" [], Label "Do not ignore effect" resolveAbility]
      else pushAll resolveAbility
    case find ((== ability) . usedAbility) investigatorUsedAbilities of
      Nothing -> do
        depth <- getWindowDepth
        traits' <- sourceTraits $ abilitySource ability
        let
          used =
            UsedAbility
              { usedAbility = ability
              , usedAbilityInitiator = iid
              , usedAbilityWindows = windows
              , usedTimes = 1
              , usedDepth = depth
              , usedAbilityTraits = traits'
              }
        pure $ a & usedAbilitiesL %~ (used :)
      Just _ -> do
        let
          updateUsed used
            | usedAbility used == ability = used {usedTimes = usedTimes used + 1}
            | otherwise = used
        pure $ a & usedAbilitiesL %~ map updateUsed
  DoNotCountUseTowardsAbilityLimit iid ability | iid == investigatorId -> do
    let
      updateUsed used
        | usedAbility used == ability = used {usedTimes = max 0 (usedTimes used - 1)}
        | otherwise = used
    pure $ a & usedAbilitiesL %~ map updateUsed
  SkillTestEnds _ _ -> do
    pure
      $ a
      & usedAbilitiesL
      %~ filter (\UsedAbility {..} -> abilityLimitType (abilityLimit usedAbility) /= Just PerTestOrAbility)
  PickSupply iid s | iid == toId a -> pure $ a & suppliesL %~ (s :)
  UseSupply iid s | iid == toId a -> pure $ a & suppliesL %~ deleteFirst s
  Blanked msg' -> runMessage msg' a
  RemovedLocation lid | investigatorLocation == lid -> do
    -- needs to look at the "real" location not as if
    pure $ a & locationL .~ LocationId nil
  _ -> pure a

getFacingDefeat :: HasGame m => InvestigatorAttrs -> m Bool
getFacingDefeat a@InvestigatorAttrs {..} = do
  canOnlyBeDefeatedByDamage <- hasModifier a CanOnlyBeDefeatedByDamage
  modifiedHealth <- field InvestigatorHealth (toId a)
  modifiedSanity <- field InvestigatorSanity (toId a)
  pure
    $ or
      [ investigatorHealthDamage a + investigatorAssignedHealthDamage >= modifiedHealth
      , and
          [ investigatorSanityDamage a + investigatorAssignedSanityDamage >= modifiedSanity
          , not canOnlyBeDefeatedByDamage
          ]
      ]

takeUpkeepResources :: InvestigatorAttrs -> Runnable InvestigatorAttrs
takeUpkeepResources a = do
  mods <- getModifiers a
  let amount = foldr (+) 1 [n | UpkeepResources n <- mods]
  if MayChooseNotToTakeUpkeepResources `elem` mods
    then do
      player <- getPlayer (toId a)
      push
        $ chooseOne player
        $ [ Label "Do not take resource(s)" []
          , Label "Take resource(s)" [TakeResources (toId a) amount (toSource a) False]
          ]
      pure a
    else pure $ a & tokensL %~ addTokens Resource amount

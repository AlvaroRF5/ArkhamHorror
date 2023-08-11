{-# LANGUAGE OverloadedLabels #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.Enemy.Runner (
  module Arkham.Enemy.Runner,
  module X,
) where

import Arkham.Prelude

import Arkham.Ability as X
import Arkham.Enemy.Helpers as X hiding (EnemyEvade, EnemyFight)
import Arkham.Enemy.Types as X
import Arkham.GameValue as X
import Arkham.Helpers.Enemy as X
import Arkham.Helpers.Message as X
import Arkham.Helpers.SkillTest as X
import Arkham.Source as X
import Arkham.Spawn as X
import Arkham.Target as X

import Arkham.Action qualified as Action
import Arkham.Attack
import Arkham.Campaigns.TheForgottenAge.Helpers
import Arkham.Card
import Arkham.Classes
import Arkham.Constants
import Arkham.Damage
import Arkham.DamageEffect
import Arkham.DefeatedBy
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Card
import Arkham.Helpers.Investigator
import Arkham.Id
import Arkham.Keyword qualified as Keyword
import Arkham.Matcher (
  AssetMatcher (..),
  EnemyMatcher (..),
  InvestigatorMatcher (..),
  LocationMatcher (..),
  PreyMatcher (..),
  investigatorEngagedWith,
  locationWithInvestigator,
  preyWith,
  replaceYourLocation,
  pattern InvestigatorCanDisengage,
  pattern MassiveEnemy,
 )
import Arkham.Message
import Arkham.Message qualified as Msg
import Arkham.Phase
import Arkham.Placement
import Arkham.Projection
import Arkham.SkillType ()
import Arkham.Timing qualified as Timing
import Arkham.Token
import Arkham.Token qualified as Token
import Arkham.Trait
import Arkham.Window (Window (..))
import Arkham.Window qualified as Window
import Data.List.Extra (firstJust)
import Data.Monoid (First (..))

{- | Handle when enemy no longer exists
When an enemy is defeated we need to remove related messages from choices
and if not more choices exist, remove the message entirely
-}
filterOutEnemyMessages :: EnemyId -> Message -> Maybe Message
filterOutEnemyMessages eid (Ask iid q) = case q of
  QuestionLabel {} -> error "currently unhandled"
  Read {} -> error "currently unhandled"
  DropDown {} -> error "currently unhandled"
  PickSupplies {} -> error "currently unhandled"
  ChooseOne msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseOne x)
  ChooseN n msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseN n x)
  ChooseSome msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseSome x)
  ChooseSome1 doneMsg msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseSome1 doneMsg x)
  ChooseUpToN n msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseUpToN n x)
  ChooseOneAtATime msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseOneAtATime x)
  ChooseUpgradeDeck -> Just (Ask iid ChooseUpgradeDeck)
  choose@ChoosePaymentAmounts {} -> Just (Ask iid choose)
  choose@ChooseAmounts {} -> Just (Ask iid choose)
filterOutEnemyMessages eid msg = case msg of
  InitiateEnemyAttack details | eid == attackEnemy details -> Nothing
  EnemyAttack details | eid == attackEnemy details -> Nothing
  Discarded (EnemyTarget eid') _ _ | eid == eid' -> Nothing
  m -> Just m

filterOutEnemyUiMessages :: EnemyId -> UI Message -> Maybe (UI Message)
filterOutEnemyUiMessages eid = \case
  TargetLabel (EnemyTarget eid') _ | eid == eid' -> Nothing
  EvadeLabel eid' _ | eid == eid' -> Nothing
  FightLabel eid' _ | eid == eid' -> Nothing
  other -> Just other

getInvestigatorsAtSameLocation :: HasGame m => EnemyAttrs -> m [InvestigatorId]
getInvestigatorsAtSameLocation attrs = do
  enemyLocation <- field EnemyLocation (toId attrs)
  case enemyLocation of
    Nothing -> pure []
    Just loc -> selectList $ InvestigatorAt $ LocationWithId loc

getPreyMatcher :: HasGame m => EnemyAttrs -> m PreyMatcher
getPreyMatcher a = do
  modifiers' <- getModifiers (toTarget a)
  pure $ foldl' applyModifier (enemyPrey a) modifiers'
 where
  applyModifier _ (ForcePrey p) = p
  applyModifier p _ = p

instance RunMessage EnemyAttrs where
  runMessage msg a@EnemyAttrs {..} = case msg of
    SetOriginalCardCode cardCode -> pure $ a & originalCardCodeL .~ cardCode
    EndPhase -> pure $ a & movedFromHunterKeywordL .~ False
    SealedChaosToken token card
      | toCardId card == toCardId a ->
          pure $ a & sealedChaosTokensL %~ (token :)
    UnsealChaosToken token -> pure $ a & sealedChaosTokensL %~ filter (/= token)
    EnemySpawnEngagedWithPrey eid | eid == enemyId -> do
      prey <- getPreyMatcher a
      preyIds <- selectList prey
      preyIdsWithLocation <-
        forToSnd
          preyIds
          (selectJust . locationWithInvestigator)
      leadInvestigatorId <- getLeadInvestigatorId
      for_ (nonEmpty preyIdsWithLocation) $ \iids ->
        push $
          chooseOrRunOne
            leadInvestigatorId
            [ targetLabel
              lid
              [ Will (EnemySpawn (Just iid) lid eid)
              , When (EnemySpawn (Just iid) lid eid)
              , EnemySpawnedAt lid eid
              , EnemyEngageInvestigator eid iid
              , After (EnemySpawn (Just iid) lid eid)
              ]
            | (iid, lid) <- toList iids
            ]
      pure a
    SetBearer (EnemyTarget eid) iid | eid == enemyId -> do
      pure $ a & bearerL ?~ iid
    EnemySpawn miid lid eid | eid == enemyId -> do
      locations' <- select Anywhere
      keywords <- getModifiedKeywords a
      if lid `notElem` locations'
        then push (Discard GameSource (EnemyTarget eid))
        else do
          if Keyword.Aloof
            `notElem` keywords
            && Keyword.Massive
            `notElem` keywords
            && not enemyExhausted
            then do
              prey <- getPreyMatcher a
              preyIds <-
                selectList $ preyWith prey $ InvestigatorAt $ LocationWithId lid
              investigatorIds <-
                if null preyIds
                  then selectList $ InvestigatorAt $ LocationWithId lid
                  else pure []
              leadInvestigatorId <- getLeadInvestigatorId
              let
                validInvestigatorIds =
                  maybe (preyIds <> investigatorIds) pure miid
              case validInvestigatorIds of
                [] -> push $ EnemyEntered eid lid
                [iid] ->
                  pushAll
                    [EnemyEntered eid lid, EnemyEngageInvestigator eid iid]
                iids ->
                  push $
                    chooseOne
                      leadInvestigatorId
                      [ targetLabel
                        iid
                        [EnemyEntered eid lid, EnemyEngageInvestigator eid iid]
                      | iid <- iids
                      ]
            else
              when (Keyword.Massive `notElem` keywords) $
                push $
                  EnemyEntered
                    eid
                    lid

          when
            (Keyword.Massive `elem` keywords)
            do
              investigatorIds <-
                selectList $
                  InvestigatorAt $
                    LocationWithId
                      lid
              pushAll $
                EnemyEntered eid lid
                  : [EnemyEngageInvestigator eid iid | iid <- investigatorIds]
      pure a
    EnemySpawnedAt lid eid | eid == enemyId -> do
      a <$ push (EnemyEntered eid lid)
    EnemyEntered eid lid | eid == enemyId -> do
      push
        =<< checkWindows
          ((`Window` Window.EnemyEnters eid lid) <$> [Timing.When, Timing.After])
      pure $ a & placementL .~ AtLocation lid
    Ready target | isTarget a target -> do
      modifiers' <- getModifiers (toTarget a)
      phase <- getPhase
      if CannotReady
        `elem` modifiers'
        || (DoesNotReadyDuringUpkeep `elem` modifiers' && phase == UpkeepPhase)
        then pure a
        else do
          leadInvestigatorId <- getLeadInvestigatorId
          enemyLocation <- field EnemyLocation enemyId
          iids <-
            fromMaybe []
              <$> traverse
                (selectList . InvestigatorAt . LocationWithId)
                enemyLocation
          keywords <- getModifiedKeywords a
          unless (null iids) $ do
            unengaged <- selectNone $ investigatorEngagedWith enemyId
            when
              ( Keyword.Aloof
                  `notElem` keywords
                  && (unengaged || Keyword.Massive `elem` keywords)
              )
              $ push
              $ chooseOne
                leadInvestigatorId
                [ TargetLabel
                  (InvestigatorTarget iid)
                  [EnemyEngageInvestigator enemyId iid]
                | iid <- iids
                ]
          pure $ a & exhaustedL .~ False
    ReadyExhausted -> do
      modifiers' <- getModifiers (toTarget a)
      let
        alternativeSources =
          mapMaybe
            ( \case
                AlternativeReady source -> Just source
                _ -> Nothing
            )
            modifiers'
      case alternativeSources of
        [] ->
          a
            <$ when
              (enemyExhausted && DoesNotReadyDuringUpkeep `notElem` modifiers')
              (pushAll $ resolve (Ready $ toTarget a))
        [source] -> a <$ push (ReadyAlternative source (toTarget a))
        _ -> error "Can not handle multiple targets yet"
    MoveToward target locationMatcher | isTarget a target -> do
      enemyLocation <- field EnemyLocation enemyId
      case enemyLocation of
        Nothing -> pure a
        Just loc -> do
          lid <- fromJustNote "can't move toward" <$> selectOne locationMatcher
          if lid == loc
            then pure a
            else do
              leadInvestigatorId <- getLeadInvestigatorId
              adjacentLocationIds <-
                selectList $ AccessibleFrom $ LocationWithId loc
              closestLocationIds <- selectList $ ClosestPathLocation loc lid
              if lid `elem` adjacentLocationIds
                then
                  push $
                    chooseOne
                      leadInvestigatorId
                      [targetLabel lid [EnemyMove enemyId lid]]
                else
                  pushAll
                    [ chooseOne
                        leadInvestigatorId
                        [ targetLabel lid' [EnemyMove enemyId lid']
                        | lid' <- closestLocationIds
                        ]
                    ]
              pure a
    MoveUntil lid target | isTarget a target -> do
      enemyLocation <- field EnemyLocation enemyId
      case enemyLocation of
        Nothing -> pure a
        Just loc ->
          if lid == loc
            then pure a
            else do
              leadInvestigatorId <- getLeadInvestigatorId
              adjacentLocationIds <-
                selectList $
                  AccessibleFrom $
                    LocationWithId
                      loc
              closestLocationIds <- selectList $ ClosestPathLocation loc lid
              if lid `elem` adjacentLocationIds
                then
                  a
                    <$ push
                      ( chooseOne
                          leadInvestigatorId
                          [targetLabel lid [EnemyMove enemyId lid]]
                      )
                else
                  a
                    <$ pushAll
                      [ chooseOne
                          leadInvestigatorId
                          [ targetLabel lid' [EnemyMove enemyId lid']
                          | lid' <- closestLocationIds
                          ]
                      , MoveUntil lid target
                      ]
    EnemyMove eid lid | eid == enemyId -> do
      willMove <- canEnterLocation eid lid
      if willMove
        then do
          enemyLocation <- field EnemyLocation enemyId
          leaveWindows <- for enemyLocation $
            \oldId -> windows [Window.EnemyLeaves eid oldId]
          pushAll $
            fromMaybe [] leaveWindows
              <> [EnemyEntered eid lid, EnemyCheckEngagement eid]
          pure $ a & placementL .~ AtLocation lid
        else a <$ push (EnemyCheckEngagement eid)
    After (EndTurn _) -> a <$ push (EnemyCheckEngagement $ toId a)
    EnemyCheckEngagement eid | eid == enemyId -> do
      keywords <- getModifiedKeywords a
      modifiers' <- getModifiers eid
      let
        modifiedFilter iid = do
          if Keyword.Massive `elem` keywords
            then pure True
            else do
              investigatorModifiers <- getModifiers iid
              canEngage <- flip allM investigatorModifiers $ \case
                CannotBeEngagedBy matcher -> notElem eid <$> select matcher
                _ -> pure True
              pure $
                canEngage && EnemyCannotEngage iid `notElem` modifiers' && CannotBeEngaged `notElem` modifiers'
      investigatorIds' <-
        filterM modifiedFilter
          =<< getInvestigatorsAtSameLocation a
      prey <- getPreyMatcher a
      preyIds <- selectList $ case prey of
        Prey m ->
          Prey $ m <> AnyInvestigator (map InvestigatorWithId investigatorIds')
        other -> other

      let investigatorIds = if null preyIds then investigatorIds' else preyIds

      leadInvestigatorId <- getLeadInvestigatorId
      unengaged <- selectNone $ investigatorEngagedWith enemyId
      when (CannotBeEngaged `elem` modifiers') $ case enemyPlacement of
        InThreatArea iid -> push $ DisengageEnemy iid enemyId
        _ -> pure ()
      when
        ( Keyword.Aloof
            `notElem` keywords
            && (unengaged || Keyword.Massive `elem` keywords)
            && CannotBeEngaged
            `notElem` modifiers'
            && not enemyExhausted
        )
        $ if Keyword.Massive `elem` keywords
          then
            pushAll
              [ EnemyEngageInvestigator eid investigatorId
              | investigatorId <- investigatorIds
              ]
          else case investigatorIds of
            [] -> pure ()
            [x] -> push $ EnemyEngageInvestigator eid x
            xs ->
              push $
                chooseOne
                  leadInvestigatorId
                  [ targetLabel
                    investigatorId
                    [EnemyEngageInvestigator eid investigatorId]
                  | investigatorId <- xs
                  ]
      pure a
    HuntersMove | not enemyExhausted -> do
      -- TODO: unengaged or not engaged with only prey
      unengaged <- selectNone $ investigatorEngagedWith enemyId
      modifiers' <- getModifiers (EnemyTarget enemyId)
      when (unengaged && CannotMove `notElem` modifiers') $ do
        keywords <- getModifiedKeywords a
        leadInvestigatorId <- getLeadInvestigatorId
        when (Keyword.Hunter `elem` keywords) $
          pushAll
            [ CheckWindow
                [leadInvestigatorId]
                [Window Timing.When (Window.MovedFromHunter enemyId)]
            , HunterMove (toId a)
            ]
      pure a
    HunterMove eid | eid == toId a && not enemyExhausted -> do
      enemyLocation <- field EnemyLocation enemyId
      case enemyLocation of
        Nothing -> pure a
        Just loc -> do
          modifiers' <- getModifiers (EnemyTarget enemyId)
          let
            matchForcedTargetLocation = \case
              DuringEnemyPhaseMustMoveToward (LocationTarget lid) -> Just lid
              _ -> Nothing
            forcedTargetLocation =
              firstJust matchForcedTargetLocation modifiers'
          -- applyConnectionMapModifier connectionMap (HunterConnectedTo lid') =
          --   unionWith (<>) connectionMap $ singletonMap loc [lid']
          -- applyConnectionMapModifier connectionMap _ = connectionMap
          -- extraConnectionsMap :: Map LocationId [LocationId] =
          --   foldl' applyConnectionMapModifier mempty modifiers'

          mLocation <- field EnemyLocation eid
          enemiesAsInvestigatorLocations <- case mLocation of
            Nothing -> pure []
            Just lid ->
              selectList
                ( LocationWithEnemy $
                    NearestEnemyToLocation lid $
                      EnemyWithModifier CountsAsInvestigatorForHunterEnemies
                )

          -- The logic here is an artifact of doing this incorrect
          -- Prey is only used for breaking ties unless we're dealing
          -- with the Only keyword for prey, so here we hardcode prey
          -- to AnyPrey and then find if there are any investigators
          -- who qualify as prey to filter
          prey <- getPreyMatcher a
          matchingClosestLocationIds <- case (forcedTargetLocation, prey) of
            (Just forcedTargetLocationId, _) ->
              -- Lure (1)
              selectList $ ClosestPathLocation loc forcedTargetLocationId
            (Nothing, BearerOf _) ->
              selectList $
                locationWithInvestigator $
                  fromJustNote
                    "must have bearer"
                    enemyBearer
            (Nothing, OnlyPrey onlyPrey) ->
              selectList $
                LocationWithInvestigator $
                  onlyPrey
                    <> NearestToEnemy
                      (EnemyWithId eid)
            (Nothing, _prey) -> do
              investigatorLocations <-
                selectList $
                  LocationWithInvestigator $
                    NearestToEnemy $
                      EnemyWithId eid
              case mLocation of
                Nothing -> pure investigatorLocations
                Just lid ->
                  selectList $
                    NearestLocationToLocation
                      lid
                      (LocationMatchAny $ map LocationWithId (enemiesAsInvestigatorLocations <> investigatorLocations))

          preyIds <- select prey
          let includeEnemies = prey == Prey Anyone

          filteredClosestLocationIds <-
            flip filterM matchingClosestLocationIds $ \lid -> do
              hasInvestigators <- notNull . intersect preyIds <$> select (InvestigatorAt (LocationWithId lid))
              hasEnemies <-
                notNull
                  <$> select (EnemyAt (LocationWithId lid) <> EnemyWithModifier CountsAsInvestigatorForHunterEnemies)
              pure $ hasInvestigators || (includeEnemies && hasEnemies)

          -- If we have any locations with prey, that takes priority, otherwise
          -- we return all locations which may have matched via AnyPrey
          let
            destinationLocationIds =
              if null filteredClosestLocationIds
                then matchingClosestLocationIds
                else filteredClosestLocationIds

          leadInvestigatorId <- getLeadInvestigatorId
          pathIds <-
            concat
              <$> traverse
                (selectList . ClosestPathLocation loc)
                destinationLocationIds
          case pathIds of
            [] -> pure a
            [lid] -> do
              pushAll
                [ EnemyMove enemyId lid
                , CheckWindow
                    [leadInvestigatorId]
                    [Window Timing.After (Window.MovedFromHunter enemyId)]
                ]
              pure $ a & movedFromHunterKeywordL .~ True
            ls -> do
              pushAll
                ( chooseOrRunOne
                    leadInvestigatorId
                    [ TargetLabel (LocationTarget l) [EnemyMove enemyId l]
                    | l <- ls
                    ]
                    : [ CheckWindow
                          [leadInvestigatorId]
                          [Window Timing.After (Window.MovedFromHunter enemyId)]
                      ]
                )
              pure $ a & movedFromHunterKeywordL .~ True
    EnemiesAttack | not enemyExhausted -> do
      modifiers' <- getModifiers (EnemyTarget enemyId)
      unless (CannotAttack `elem` modifiers') $ do
        iids <- selectList $ investigatorEngagedWith enemyId
        pushAll $
          map
            ( \iid ->
                EnemyWillAttack $
                  (enemyAttack enemyId a iid)
                    { attackDamageStrategy = enemyDamageStrategy
                    , attackExhaustsEnemy = True
                    }
            )
            iids
      pure a
    AttackEnemy iid eid source mTarget skillType | eid == enemyId -> do
      enemyFight' <- modifiedEnemyFight iid a
      push $
        fight
          iid
          source
          (maybe (EnemyTarget eid) (ProxyTarget (EnemyTarget eid)) mTarget)
          skillType
          enemyFight'
      pure a
    PassedSkillTest iid (Just Action.Fight) source (SkillTestInitiatorTarget target) _ n
      | isActionTarget a target ->
          do
            whenWindow <-
              checkWindows
                [Window Timing.When (Window.SuccessfulAttackEnemy iid enemyId n)]
            afterSuccessfulWindow <-
              checkWindows
                [Window Timing.After (Window.SuccessfulAttackEnemy iid enemyId n)]
            afterWindow <-
              checkWindows
                [Window Timing.After (Window.EnemyAttacked iid source enemyId)]
            a
              <$ pushAll
                [ whenWindow
                , Successful
                    (Action.Fight, toProxyTarget target)
                    iid
                    source
                    (toActionTarget target)
                    n
                , afterSuccessfulWindow
                , afterWindow
                ]
    Successful (Action.Fight, _) iid source target _ | isTarget a target -> do
      a <$ push (InvestigatorDamageEnemy iid enemyId source)
    FailedSkillTest iid (Just Action.Fight) source (SkillTestInitiatorTarget target) _ n
      | isTarget a target ->
          do
            keywords <- getModifiedKeywords a
            modifiers' <- getModifiers iid
            pushAll $
              [ FailedAttackEnemy iid enemyId
              , CheckWindow
                  [iid]
                  [Window Timing.After (Window.FailAttackEnemy iid enemyId n)]
              , CheckWindow
                  [iid]
                  [Window Timing.After (Window.EnemyAttacked iid source enemyId)]
              ]
                <> [ EnemyAttack $
                    (enemyAttack enemyId a iid)
                      { attackDamageStrategy = enemyDamageStrategy
                      }
                   | Keyword.Retaliate
                      `elem` keywords
                   , IgnoreRetaliate
                      `notElem` modifiers'
                   , not enemyExhausted
                      || CanRetaliateWhileExhausted
                      `elem` modifiers'
                   ]
            pure a
    EnemyAttackIfEngaged eid miid | eid == enemyId -> do
      case miid of
        Just iid -> do
          shouldAttack <- member iid <$> select (investigatorEngagedWith eid)
          when shouldAttack $
            push $
              EnemyAttack $
                (enemyAttack enemyId a iid)
                  { attackDamageStrategy = enemyDamageStrategy
                  }
        Nothing -> do
          iids <- selectList $ investigatorEngagedWith eid
          pushAll
            [ EnemyAttack $
              (enemyAttack enemyId a iid)
                { attackDamageStrategy = enemyDamageStrategy
                }
            | iid <- iids
            ]
      pure a
    EnemyEvaded iid eid | eid == enemyId -> do
      modifiers <- getModifiers (InvestigatorTarget iid)
      lid <- fieldJust EnemyLocation eid
      let
        updatePlacement =
          if DoNotDisengageEvaded `elem` modifiers
            then id
            else placementL .~ AtLocation lid
        updateExhausted =
          if DoNotExhaustEvaded `elem` modifiers
            then id
            else exhaustedL .~ True
      pure $ a & updatePlacement & updateExhausted
    Exhaust (isTarget a -> True) -> pure $ a & exhaustedL .~ True
    TryEvadeEnemy iid eid source mTarget skillType | eid == enemyId -> do
      mEnemyEvade' <- modifiedEnemyEvade a
      case mEnemyEvade' of
        Just n ->
          push $
            evade
              iid
              source
              (maybe (EnemyTarget eid) (ProxyTarget (EnemyTarget eid)) mTarget)
              skillType
              n
        Nothing -> error "No evade value"
      pure a
    PassedSkillTest iid (Just Action.Evade) source (SkillTestInitiatorTarget target) _ n
      | isActionTarget a target ->
          do
            whenWindow <-
              checkWindows
                [Window Timing.When (Window.SuccessfulEvadeEnemy iid enemyId n)]
            afterWindow <-
              checkWindows
                [Window Timing.After (Window.SuccessfulEvadeEnemy iid enemyId n)]
            a
              <$ pushAll
                [ whenWindow
                , Successful
                    (Action.Evade, toProxyTarget target)
                    iid
                    source
                    (toActionTarget target)
                    n
                , afterWindow
                ]
    Successful (Action.Evade, _) iid _ target _ | isTarget a target -> do
      a <$ push (EnemyEvaded iid enemyId)
    FailedSkillTest iid (Just Action.Evade) _ (SkillTestInitiatorTarget target) _ n
      | isTarget a target ->
          do
            keywords <- getModifiedKeywords a
            whenWindow <-
              checkWindows
                [Window Timing.When (Window.FailEvadeEnemy iid enemyId n)]
            afterWindow <-
              checkWindows
                [Window Timing.After (Window.FailEvadeEnemy iid enemyId n)]
            pushAll $
              [whenWindow, afterWindow]
                <> [ EnemyAttack $
                    (enemyAttack enemyId a iid)
                      { attackDamageStrategy = enemyDamageStrategy
                      }
                   | Keyword.Alert `elem` keywords
                   ]
            pure a
    InitiateEnemyAttack details | attackEnemy details == enemyId -> do
      push $ EnemyAttack details
      pure a
    EnemyAttack details | attackEnemy details == enemyId -> do
      whenAttacksWindow <-
        checkWindows
          [Window Timing.When (Window.EnemyAttacks details)]
      afterAttacksEventIfCancelledWindow <-
        checkWindows
          [Window Timing.After (Window.EnemyAttacksEvenIfCancelled details)]
      whenWouldAttackWindow <-
        checkWindows
          [Window Timing.When (Window.EnemyWouldAttack details)]
      pushAll
        [ whenWouldAttackWindow
        , whenAttacksWindow
        , PerformEnemyAttack details
        , After (PerformEnemyAttack details)
        , afterAttacksEventIfCancelledWindow
        ]
      pure a
    PerformEnemyAttack details | attackEnemy details == enemyId -> do
      modifiers <- getModifiers (attackTarget details)
      sourceModifiers <- getModifiers (sourceToTarget $ attackSource details)

      let
        applyModifiers cards (CancelAttacksByEnemies c n) = do
          canceled <- member enemyId <$> select n
          pure $
            if canceled
              then c : cards
              else cards
        applyModifiers m _ = pure m

      cardsThatCanceled <- foldM applyModifiers [] modifiers

      ignoreWindows <- for cardsThatCanceled $ \card -> checkWindows [Window Timing.After (Window.CancelledOrIgnoredCardOrGameEffect $ CardSource card)]

      let
        allowAttack =
          and
            [ null cardsThatCanceled
            , EffectsCannotBeCanceled `notElem` sourceModifiers && attackCanBeCanceled details
            ]

      case attackTarget details of
        InvestigatorTarget iid ->
          pushAll $
            [ InvestigatorAssignDamage
              iid
              (EnemyAttackSource enemyId)
              (attackDamageStrategy details)
              enemyHealthDamage
              enemySanityDamage
            | allowAttack
            ]
              <> [Exhaust (toTarget a) | allowAttack, attackExhaustsEnemy details]
              <> ignoreWindows
              <> [After (EnemyAttack details)]
        _ -> error "Unhandled"
      pure a
    HealDamage (EnemyTarget eid) source n | eid == enemyId -> do
      afterWindow <-
        checkWindows
          [Window Timing.After (Window.Healed DamageType (toTarget a) source n)]
      push afterWindow
      pure $ a & tokensL %~ subtractTokens Token.Damage n
    HealAllDamage (EnemyTarget eid) source | eid == enemyId -> do
      afterWindow <-
        checkWindows
          [ Window
              Timing.After
              (Window.Healed DamageType (toTarget a) source (enemyDamage a))
          ]
      push afterWindow
      pure $ a & tokensL %~ removeAllTokens Token.Damage
    Msg.EnemyDamage eid damageAssignment | eid == enemyId -> do
      let
        source = damageAssignmentSource damageAssignment
        damageEffect = damageAssignmentDamageEffect damageAssignment
        damageAmount = damageAssignmentAmount damageAssignment
      canDamage <- sourceCanDamageEnemy eid source
      when
        canDamage
        do
          dealtDamageWhenMsg <-
            checkWindows
              [ Window
                  Timing.When
                  ( Window.DealtDamage
                      source
                      damageEffect
                      (toTarget a)
                      damageAmount
                  )
              ]
          dealtDamageAfterMsg <-
            checkWindows
              [ Window
                  Timing.After
                  ( Window.DealtDamage
                      source
                      damageEffect
                      (toTarget a)
                      damageAmount
                  )
              ]
          takeDamageWhenMsg <-
            checkWindows
              [ Window
                  Timing.When
                  (Window.TakeDamage source damageEffect $ toTarget a)
              ]
          takeDamageAfterMsg <-
            checkWindows
              [ Window
                  Timing.After
                  (Window.TakeDamage source damageEffect $ toTarget a)
              ]
          pushAll
            [ dealtDamageWhenMsg
            , dealtDamageAfterMsg
            , takeDamageWhenMsg
            , EnemyDamaged eid damageAssignment
            , takeDamageAfterMsg
            ]
      pure a
    EnemyDamaged eid damageAssignment | eid == enemyId -> do
      let
        direct = damageAssignmentDirect damageAssignment
        source = damageAssignmentSource damageAssignment
        amount = damageAssignmentAmount damageAssignment
      canDamage <- sourceCanDamageEnemy eid source
      if canDamage
        then do
          amount' <- getModifiedDamageAmount a direct amount
          let
            damageAssignment' =
              damageAssignment {damageAssignmentAmount = amount'}
            combine l r =
              if damageAssignmentDamageEffect l
                == damageAssignmentDamageEffect r
                then
                  l
                    { damageAssignmentAmount =
                        damageAssignmentAmount l
                          + damageAssignmentAmount r
                    }
                else
                  error $
                    "mismatched damage assignments\n\nassignment: "
                      <> show l
                      <> "\nnew assignment: "
                      <> show r
          unless (damageAssignmentDelayed damageAssignment') $
            push $
              CheckDefeated source
          pure $
            a
              & assignedDamageL
              %~ insertWith combine source damageAssignment'
        else pure a
    CheckDefeated source -> do
      do
        let mDamageAssignment = lookup source enemyAssignedDamage
        case mDamageAssignment of
          Nothing -> pure a
          Just da -> do
            canBeDefeated <- withoutModifier a CannotBeDefeated
            modifiers' <- getModifiers (toTarget a)
            let
              eid = toId a
              amount' = damageAssignmentAmount da
              damageEffect = damageAssignmentDamageEffect da
              canOnlyBeDefeatedByModifier = \case
                CanOnlyBeDefeatedBy source' -> First (Just source')
                _ -> First Nothing
              mOnlyBeDefeatedByModifier =
                getFirst $ foldMap canOnlyBeDefeatedByModifier modifiers'
              validDefeat =
                canBeDefeated
                  && maybe True (== source) mOnlyBeDefeatedByModifier
            when validDefeat $ do
              modifiedHealth <- getModifiedHealth a
              when (enemyDamage a + amount' >= modifiedHealth) $ do
                let excess = (enemyDamage a + amount') - modifiedHealth
                whenMsg <-
                  checkWindows
                    [Window Timing.When (Window.EnemyWouldBeDefeated eid)]
                afterMsg <-
                  checkWindows
                    [Window Timing.After (Window.EnemyWouldBeDefeated eid)]
                whenExcessMsg <-
                  checkWindows
                    [ Window
                      Timing.When
                      ( Window.DealtExcessDamage
                          source
                          damageEffect
                          (EnemyTarget eid)
                          excess
                      )
                    | excess > 0
                    ]
                afterExcessMsg <-
                  checkWindows
                    [ Window
                      Timing.After
                      ( Window.DealtExcessDamage
                          source
                          damageEffect
                          (EnemyTarget eid)
                          excess
                      )
                    | excess > 0
                    ]
                pushAll
                  [ whenExcessMsg
                  , afterExcessMsg
                  , whenMsg
                  , afterMsg
                  , EnemyDefeated
                      eid
                      (toCardId a)
                      source
                      (setToList $ toTraits a)
                  ]
            pure $ a & tokensL %~ addTokens Token.Damage amount' & assignedDamageL .~ mempty
    DefeatEnemy eid _ source | eid == enemyId -> do
      canBeDefeated <- withoutModifier a CannotBeDefeated
      modifiedHealth <- getModifiedHealth a
      canOnlyBeDefeatedByDamage <- hasModifier a CanOnlyBeDefeatedByDamage
      modifiers' <- getModifiers (toTarget a)
      let
        defeatedByDamage = enemyDamage a >= modifiedHealth
        canOnlyBeDefeatedByModifier = \case
          CanOnlyBeDefeatedBy source' -> First (Just source')
          _ -> First Nothing
        mOnlyBeDefeatedByModifier =
          getFirst $ foldMap canOnlyBeDefeatedByModifier modifiers'
        validDefeat =
          canBeDefeated
            && maybe True (== source) mOnlyBeDefeatedByModifier
            && (not canOnlyBeDefeatedByDamage || defeatedByDamage)
      when validDefeat $
        push $
          EnemyDefeated
            eid
            (toCardId a)
            source
            (setToList $ toTraits a)
      pure a
    EnemyDefeated eid _ source _ | eid == toId a -> do
      modifiedHealth <- getModifiedHealth a
      let
        defeatedByDamage = enemyDamage a >= modifiedHealth
        defeatedBy = if defeatedByDamage then DefeatedByDamage source else DefeatedByOther source
      miid <- getSourceController source
      whenMsg <-
        checkWindows
          [Window Timing.When (Window.EnemyDefeated miid defeatedBy eid)]
      afterMsg <-
        checkWindows
          [Window Timing.After (Window.EnemyDefeated miid defeatedBy eid)]
      victory <- getVictoryPoints eid
      vengeance <- getVengeancePoints eid
      let
        victoryMsgs =
          [DefeatedAddToVictory $ toTarget a | isJust (victory <|> vengeance)]
        defeatMsgs =
          if isJust (victory <|> vengeance)
            then resolve $ RemoveEnemy eid
            else [Discard GameSource $ toTarget a]

      withQueue_ $ mapMaybe (filterOutEnemyMessages eid)

      pushAll $
        [whenMsg, When msg, After msg]
          <> victoryMsgs
          <> [afterMsg]
          <> defeatMsgs
      pure $ a & keysL .~ mempty
    Discard source target | a `isTarget` target -> do
      windows' <- windows [Window.WouldBeDiscarded (toTarget a)]
      pushAll $
        windows'
          <> [ RemovedFromPlay $ toSource a
             , Discarded (toTarget a) source (toCard a)
             ]
      pure $ a & keysL .~ mempty
    PutOnTopOfDeck iid deck target | a `isTarget` target -> do
      pushAll $
        resolve (RemoveEnemy $ toId a)
          <> [PutCardOnTopOfDeck iid deck (toCard a)]
      pure a
    PutOnBottomOfDeck iid deck target | a `isTarget` target -> do
      pushAll $
        resolve (RemoveEnemy $ toId a)
          <> [PutCardOnBottomOfDeck iid deck (toCard a)]
      pure a
    RemovedFromPlay source | isSource a source -> do
      enemyAssets <- selectList $ EnemyAsset enemyId
      windowMsg <-
        checkWindows $
          (`Window` Window.LeavePlay (toTarget a))
            <$> [Timing.When, Timing.After]
      pushAll $
        windowMsg
          : map (Discard GameSource . AssetTarget) enemyAssets
            <> [UnsealChaosToken token | token <- enemySealedChaosTokens]
      pure a
    EnemyEngageInvestigator eid iid | eid == enemyId -> do
      lid <- getJustLocation iid
      enemyLocation <- field EnemyLocation eid
      when (Just lid /= enemyLocation) $ push $ EnemyEntered eid lid
      massive <- eid <=~> MassiveEnemy
      pure $ a & (if massive then id else placementL .~ InThreatArea iid)
    EngageEnemy iid eid False | eid == enemyId -> do
      massive <- eid <=~> MassiveEnemy
      pure $ a & (if massive then id else placementL .~ InThreatArea iid)
    WhenWillEnterLocation iid lid -> do
      shouldRespoond <- member iid <$> select (investigatorEngagedWith enemyId)
      when shouldRespoond $ do
        keywords <- getModifiedKeywords a
        willMove <- canEnterLocation enemyId lid
        push $
          if Keyword.Massive `notElem` keywords && willMove
            then EnemyEntered enemyId lid
            else DisengageEnemy iid enemyId
      pure a
    CheckAttackOfOpportunity iid isFast | not isFast && not enemyExhausted -> do
      willAttack <- member iid <$> select (investigatorEngagedWith enemyId)
      when willAttack $ do
        modifiers' <- getModifiers enemyId
        unless (CannotMakeAttacksOfOpportunity `elem` modifiers') $
          push $
            EnemyWillAttack $
              EnemyAttackDetails
                { attackEnemy = enemyId
                , attackTarget = InvestigatorTarget iid
                , attackDamageStrategy = enemyDamageStrategy
                , attackType = AttackOfOpportunity
                , attackExhaustsEnemy = False
                , attackSource = toSource a
                , attackCanBeCanceled = True
                }
      pure a
    InvestigatorDrawEnemy iid eid | eid == enemyId -> do
      lid <- getJustLocation iid
      modifiers' <- getModifiers enemyId
      let
        getModifiedSpawnAt [] = enemySpawnAt
        getModifiedSpawnAt (ForceSpawnLocation m : _) = Just $ SpawnLocation m
        getModifiedSpawnAt (_ : xs) = getModifiedSpawnAt xs
        spawnAtMatcher = getModifiedSpawnAt modifiers'
      case spawnAtMatcher of
        Nothing -> do
          windows' <-
            checkWindows
              [Window Timing.When (Window.EnemyWouldSpawnAt eid lid)]
          pushAll $ windows' : resolve (EnemySpawn (Just iid) lid eid)
        Just matcher -> do
          let
            applyMatcherExclusions ms (SpawnAtFirst sas) =
              SpawnAtFirst (map (applyMatcherExclusions ms) sas)
            applyMatcherExclusions [] m = m
            applyMatcherExclusions (CannotSpawnIn n : xs) (SpawnLocation m) =
              applyMatcherExclusions xs (SpawnLocation $ m <> NotLocation n)
            applyMatcherExclusions (_ : xs) m = applyMatcherExclusions xs m
          spawnAt enemyId (applyMatcherExclusions modifiers' matcher)
      pure a
    EnemySpawnAtLocationMatching miid locationMatcher eid | eid == enemyId -> do
      activeInvestigatorId <- getActiveInvestigatorId
      yourLocation <- selectOne $ locationWithInvestigator activeInvestigatorId
      lids <- selectList $ replaceYourLocation activeInvestigatorId yourLocation locationMatcher
      leadInvestigatorId <- getLeadInvestigatorId
      case lids of
        [] ->
          pushAll $
            Discard GameSource (EnemyTarget eid)
              : [ Surge iid (toSource a)
                | enemySurgeIfUnableToSpawn
                , iid <- maybeToList miid
                ]
        [lid] -> do
          windows' <-
            checkWindows
              [Window Timing.When (Window.EnemyWouldSpawnAt eid lid)]
          pushAll $ windows' : resolve (EnemySpawn miid lid eid)
        xs -> spawnAtOneOf (fromMaybe leadInvestigatorId miid) eid xs
      pure a
    InvestigatorEliminated iid -> case enemyPlacement of
      InThreatArea iid' | iid == iid' -> do
        lid <- getJustLocation iid
        pure $ a & placementL .~ AtLocation lid
      _ -> pure a
    DisengageEnemy iid eid | eid == enemyId -> case enemyPlacement of
      InThreatArea iid' | iid == iid' -> do
        canDisengage <- iid <=~> InvestigatorCanDisengage
        if canDisengage
          then do
            lid <- getJustLocation iid
            pure $ a & placementL .~ AtLocation lid
          else pure a
      _ -> pure a
    DisengageEnemyFromAll eid | eid == enemyId -> case enemyPlacement of
      InThreatArea iid -> do
        canDisengage <- iid <=~> InvestigatorCanDisengage
        if canDisengage
          then do
            lid <- getJustLocation iid
            pure $ a & placementL .~ AtLocation lid
          else pure a
      _ -> pure a
    RemoveAllClues _ target | isTarget a target -> pure $ a & tokensL %~ removeAllTokens Clue
    RemoveAllDoom _ target | isTarget a target -> pure $ a & tokensL %~ removeAllTokens Doom
    RemoveTokens _ target token amount | isTarget a target -> do
      pure $ a & tokensL %~ subtractTokens token amount
    PlaceTokens source target Doom amount | isTarget a target -> do
      modifiers' <- getModifiers (toTarget a)
      if CannotPlaceDoomOnThis `elem` modifiers'
        then pure a
        else do
          windows' <- windows [Window.PlacedDoom source (toTarget a) amount]
          pushAll windows'
          pure $ a & tokensL %~ addTokens Doom amount
    PlaceTokens source target token n | isTarget a target -> do
      case token of
        Clue -> do
          windows' <- windows [Window.PlacedClues source (toTarget a) n]
          pushAll windows'
        _ -> pure ()
      pure $ a & tokensL %~ addTokens token n
    PlaceKey (isTarget a -> True) k -> do
      pure $ a & keysL %~ insertSet k
    PlaceKey (isTarget a -> False) k -> do
      pure $ a & keysL %~ deleteSet k
    RemoveClues _ target n | isTarget a target -> do
      pure $ a & tokensL %~ subtractTokens Clue n
    FlipClues target n | isTarget a target -> do
      pure $ a & tokensL %~ flipClues n
    PlaceEnemyInVoid eid | eid == enemyId -> do
      withQueue_ $ mapMaybe (filterOutEnemyMessages eid)
      pure $
        a
          & (placementL .~ OutOfPlay VoidZone)
          & (exhaustedL .~ False)
          & (tokensL %~ removeAllTokens Doom . removeAllTokens Clue . removeAllTokens Token.Damage)
    PlaceEnemy eid placement | eid == enemyId -> do
      push $ EnemyCheckEngagement eid
      pure $ a & placementL .~ placement
    Blanked msg' -> runMessage msg' a
    UseCardAbility iid (isSource a -> True) AbilityAttack _ _ -> do
      push $ FightEnemy iid (toId a) (toSource iid) Nothing #combat False
      pure a
    UseCardAbility iid (isSource a -> True) AbilityEvade _ _ -> do
      push $ EvadeEnemy iid (toId a) (toSource iid) Nothing #agility False
      pure a
    UseCardAbility iid (isSource a -> True) AbilityEngage _ _ -> do
      push $ EngageEnemy iid (toId a) False
      pure a
    AssignDamage target | isTarget a target -> do
      let sources = keys enemyAssignedDamage
      pushAll $ map CheckDefeated sources
      pure a
    _ -> pure a

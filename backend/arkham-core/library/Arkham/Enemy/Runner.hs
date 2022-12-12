{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE OverloadedLabels #-}
module Arkham.Enemy.Runner
  ( module Arkham.Enemy.Runner
  , module X
  ) where

import Arkham.Prelude

import Arkham.Enemy.Helpers as X hiding ( EnemyEvade, EnemyFight )
import Arkham.Enemy.Types as X
import Arkham.GameValue as X
import Arkham.Helpers.Enemy as X
import Arkham.Helpers.Message as X
import Arkham.Spawn as X

import Arkham.Action qualified as Action
import Arkham.Attack
import Arkham.Card
import Arkham.Classes
import Arkham.Constants
import Arkham.DamageEffect
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Investigator
import Arkham.Id
import Arkham.Keyword qualified as Keyword
import Arkham.Matcher
  ( AssetMatcher (..)
  , EnemyMatcher (..)
  , InvestigatorMatcher (..)
  , LocationMatcher (..)
  , PreyMatcher (..)
  , investigatorEngagedWith
  , locationWithInvestigator
  , pattern InvestigatorCanDisengage
  , pattern MassiveEnemy
  , preyWith
  )
import Arkham.Message
import Arkham.Message qualified as Msg
import Arkham.Phase
import Arkham.Placement
import Arkham.Projection
import Arkham.SkillType ()
import Arkham.Source
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Trait
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window
import Data.List.Extra ( firstJust )
import Data.Monoid ( First (..) )

-- | Handle when enemy no longer exists
-- When an enemy is defeated we need to remove related messages from choices
-- and if not more choices exist, remove the message entirely
filterOutEnemyMessages :: EnemyId -> Message -> Maybe Message
filterOutEnemyMessages eid (Ask iid q) = case q of
  QuestionLabel{} -> error "currently unhandled"
  Read{} -> error "currently unhandled"
  ChooseOne msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseOne x)
  ChooseN n msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseN n x)
  ChooseSome msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseSome x)
  ChooseUpToN n msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseUpToN n x)
  ChooseOneAtATime msgs -> case mapMaybe (filterOutEnemyUiMessages eid) msgs of
    [] -> Nothing
    x -> Just (Ask iid $ ChooseOneAtATime x)
  ChooseUpgradeDeck -> Just (Ask iid ChooseUpgradeDeck)
  choose@ChoosePaymentAmounts{} -> Just (Ask iid choose)
  choose@ChooseAmounts{} -> Just (Ask iid choose)
filterOutEnemyMessages eid msg = case msg of
  InitiateEnemyAttack _ eid' _ | eid == eid' -> Nothing
  EnemyAttack _ eid' _ _ | eid == eid' -> Nothing
  Discarded (EnemyTarget eid') _ | eid == eid' -> Nothing
  m -> Just m

filterOutEnemyUiMessages :: EnemyId -> UI Message -> Maybe (UI Message)
filterOutEnemyUiMessages eid = \case
  TargetLabel (EnemyTarget eid') _ | eid == eid' -> Nothing
  EvadeLabel eid' _ | eid == eid' -> Nothing
  FightLabel eid' _ | eid == eid' -> Nothing
  other -> Just other

getInvestigatorsAtSameLocation
  :: (Monad m, HasGame m) => EnemyAttrs -> m [InvestigatorId]
getInvestigatorsAtSameLocation attrs = do
  enemyLocation <- field EnemyLocation (toId attrs)
  case enemyLocation of
    Nothing -> pure []
    Just loc -> selectList $ InvestigatorAt $ LocationWithId loc

instance RunMessage EnemyAttrs where
  runMessage msg a@EnemyAttrs {..} = case msg of
    SetOriginalCardCode cardCode -> pure $ a & originalCardCodeL .~ cardCode
    EndPhase -> pure $ a & movedFromHunterKeywordL .~ False
    SealedToken token card | toCardId card == toCardId a ->
      pure $ a & sealedTokensL %~ (token :)
    UnsealToken token -> pure $ a & sealedTokensL %~ filter (/= token)
    EnemySpawnEngagedWithPrey eid | eid == enemyId -> do
      preyIds <- selectList enemyPrey
      preyIdsWithLocation <- forToSnd
        preyIds
        (selectJust . locationWithInvestigator)
      leadInvestigatorId <- getLeadInvestigatorId
      for_ (nonEmpty preyIdsWithLocation) $ \iids -> push $ chooseOrRunOne
        leadInvestigatorId
        [ targetLabel
            lid
            [EnemySpawnedAt lid eid, EnemyEngageInvestigator eid iid]
        | (iid, lid) <- toList iids
        ]
      pure a
    SetBearer (EnemyTarget eid) iid | eid == enemyId -> do
      pure $ a & bearerL ?~ iid
    EnemySpawn miid lid eid | eid == enemyId -> do
      locations' <- select Anywhere
      keywords <- getModifiedKeywords a
      if lid `notElem` locations'
        then a <$ push (Discard (EnemyTarget eid))
        else do
          if Keyword.Aloof
            `notElem` keywords
            && Keyword.Massive
            `notElem` keywords
            && not enemyExhausted
          then
            do
              preyIds <-
                selectList
                $ preyWith enemyPrey
                $ InvestigatorAt
                $ LocationWithId lid
              investigatorIds <- if null preyIds
                then selectList $ InvestigatorAt $ LocationWithId lid
                else pure []
              leadInvestigatorId <- getLeadInvestigatorId
              let
                validInvestigatorIds =
                  maybe (preyIds <> investigatorIds) pure miid
              case validInvestigatorIds of
                [] -> push $ EnemyEntered eid lid
                [iid] -> pushAll
                  [EnemyEntered eid lid, EnemyEngageInvestigator eid iid]
                iids -> push
                  (chooseOne
                    leadInvestigatorId
                    [ targetLabel
                        iid
                        [EnemyEntered eid lid, EnemyEngageInvestigator eid iid]
                    | iid <- iids
                    ]
                  )
          else
            when (Keyword.Massive `notElem` keywords) $ push $ EnemyEntered
              eid
              lid

          when
            (Keyword.Massive `elem` keywords)
            do
              investigatorIds <- selectList $ InvestigatorAt $ LocationWithId
                lid
              pushAll
                $ EnemyEntered eid lid
                : [ EnemyEngageInvestigator eid iid | iid <- investigatorIds ]
          pure a
    EnemySpawnedAt lid eid | eid == enemyId -> do
      a <$ push (EnemyEntered eid lid)
    EnemyEntered eid lid | eid == enemyId -> do
      push =<< checkWindows
        ((`Window` Window.EnemyEnters eid lid) <$> [Timing.When, Timing.After])
      pure $ a & placementL .~ AtLocation lid
    Ready target | isTarget a target -> do
      modifiers' <- getModifiers (toTarget a)
      phase <- getPhase
      if CannotReady
        `elem` modifiers'
        || (DoesNotReadyDuringUpkeep `elem` modifiers' && phase == UpkeepPhase)
      then
        pure a
      else
        do
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
                (Keyword.Aloof
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
        alternativeSources = mapMaybe
          (\case
            AlternativeReady source -> Just source
            _ -> Nothing
          )
          modifiers'
      case alternativeSources of
        [] -> a <$ when
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
                then push $ chooseOne
                  leadInvestigatorId
                  [targetLabel lid [EnemyMove enemyId lid]]
                else pushAll
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
        Just loc -> if lid == loc
          then pure a
          else do
            leadInvestigatorId <- getLeadInvestigatorId
            adjacentLocationIds <- selectList $ AccessibleFrom $ LocationWithId
              loc
            closestLocationIds <- selectList $ ClosestPathLocation loc lid
            if lid `elem` adjacentLocationIds
              then
                a
                  <$ push
                       (chooseOne
                         leadInvestigatorId
                         [targetLabel lid [EnemyMove enemyId lid]]
                       )
              else a <$ pushAll
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
          leaveWindows <- for enemyLocation
            $ \oldId -> windows [Window.EnemyLeaves eid oldId]
          pushAll
            $ fromMaybe [] leaveWindows
            <> [EnemyEntered eid lid, EnemyCheckEngagement eid]
          pure $ a & placementL .~ AtLocation lid
        else a <$ push (EnemyCheckEngagement eid)
    After (EndTurn _) -> a <$ push (EnemyCheckEngagement $ toId a)
    EnemyCheckEngagement eid | eid == enemyId -> do
      keywords <- getModifiedKeywords a
      modifiers' <- getModifiers (EnemyTarget eid)
      let
        modifiedFilter iid = do
          if Keyword.Massive `elem` keywords
            then pure True
            else do
              investigatorModifiers <- getModifiers (InvestigatorTarget iid)
              canEngage <- flip allM investigatorModifiers $ \case
                CannotBeEngagedBy matcher -> notElem eid <$> select matcher
                _ -> pure True
              pure $ canEngage && EnemyCannotEngage iid `notElem` modifiers'
      investigatorIds <- filterM modifiedFilter
        =<< getInvestigatorsAtSameLocation a
      leadInvestigatorId <- getLeadInvestigatorId
      unengaged <- selectNone $ investigatorEngagedWith enemyId
      when
          (Keyword.Aloof
          `notElem` keywords
          && (unengaged || Keyword.Massive `elem` keywords)
          && not enemyExhausted
          )
        $ if Keyword.Massive `elem` keywords
            then pushAll
              [ EnemyEngageInvestigator eid investigatorId
              | investigatorId <- investigatorIds
              ]
            else case investigatorIds of
              [] -> pure ()
              [x] -> push $ EnemyEngageInvestigator eid x
              xs -> push $ chooseOne
                leadInvestigatorId
                [ targetLabel
                    investigatorId
                    [EnemyEngageInvestigator eid investigatorId]
                | investigatorId <- xs
                ]
      pure a
    HuntersMove | not enemyExhausted -> do
      unengaged <- selectNone $ investigatorEngagedWith enemyId
      when unengaged $ do
        keywords <- getModifiedKeywords a
        leadInvestigatorId <- getLeadInvestigatorId
        when (Keyword.Hunter `elem` keywords) $ pushAll
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
            -- extraConnectionsMap :: HashMap LocationId [LocationId] =
            --   foldl' applyConnectionMapModifier mempty modifiers'

          -- The logic here is an artifact of doing this incorrect
          -- Prey is only used for breaking ties unless we're dealing
          -- with the Only keyword for prey, so here we hardcode prey
          -- to AnyPrey and then find if there are any investigators
          -- who qualify as prey to filter
          matchingClosestLocationIds <-
            case (forcedTargetLocation, enemyPrey) of
              (Just _forcedTargetLocationId, _) -> error "TODO: MUST FIX"
                -- map unClosestPathLocationId <$> getSetList
                --   (loc, forcedTargetLocationId, extraConnectionsMap)
              (Nothing, BearerOf _) ->
                selectList $ locationWithInvestigator $ fromJustNote
                  "must have bearer"
                  enemyBearer
              (Nothing, OnlyPrey prey) ->
                selectList $ LocationWithInvestigator $ prey <> NearestToEnemy
                  (EnemyWithId eid)
              (Nothing, _prey) ->
                selectList
                  $ LocationWithInvestigator
                  $ NearestToEnemy
                  $ EnemyWithId eid

          preyIds <- select enemyPrey

          filteredClosestLocationIds <-
            flip filterM matchingClosestLocationIds $ \lid ->
              notNull . intersect preyIds <$> select
                (InvestigatorAt $ LocationWithId lid)

          -- If we have any locations with prey, that takes priority, otherwise
          -- we return all locations which may have matched via AnyPrey
          let
            destinationLocationIds = if null filteredClosestLocationIds
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
                (chooseOne
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
        pushAll $ map
          (\iid -> EnemyWillAttack iid enemyId enemyDamageStrategy RegularAttack
          )
          iids
      pure a
    AttackEnemy iid eid source mTarget skillType | eid == enemyId -> do
      enemyFight' <- modifiedEnemyFight a
      push $ BeginSkillTest
        iid
        source
        (maybe (EnemyTarget eid) (ProxyTarget (EnemyTarget eid)) mTarget)
        (Just Action.Fight)
        skillType
        enemyFight'
      pure a
    PassedSkillTest iid (Just Action.Fight) source (SkillTestInitiatorTarget target) _ n
      | isActionTarget a target
      -> do
        whenWindow <- checkWindows
          [Window Timing.When (Window.SuccessfulAttackEnemy iid enemyId n)]
        afterSuccessfulWindow <- checkWindows
          [Window Timing.After (Window.SuccessfulAttackEnemy iid enemyId n)]
        afterWindow <- checkWindows
          [Window Timing.After (Window.EnemyAttacked iid source enemyId)]
        a <$ pushAll
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
      | isTarget a target
      -> do
        keywords <- getModifiedKeywords a
        modifiers' <- getModifiers (InvestigatorTarget iid)
        a <$ pushAll
          ([ FailedAttackEnemy iid enemyId
           , CheckWindow
             [iid]
             [Window Timing.After (Window.FailAttackEnemy iid enemyId n)]
           , CheckWindow
             [iid]
             [Window Timing.After (Window.EnemyAttacked iid source enemyId)]
           ]
          <> [ EnemyAttack iid enemyId enemyDamageStrategy RegularAttack
             | Keyword.Retaliate
               `elem` keywords
               && IgnoreRetaliate
               `notElem` modifiers'
               && (not enemyExhausted
                  || CanRetaliateWhileExhausted
                  `elem` modifiers'
                  )
             ]
          )
    EnemyAttackIfEngaged eid miid | eid == enemyId -> do
      case miid of
        Just iid -> do
          shouldAttack <- member iid <$> select (investigatorEngagedWith eid)
          when shouldAttack $ push $ EnemyAttack
            iid
            enemyId
            enemyDamageStrategy
            RegularAttack
        Nothing -> do
          iids <- selectList $ investigatorEngagedWith eid
          pushAll
            [ EnemyAttack iid enemyId enemyDamageStrategy RegularAttack
            | iid <- iids
            ]
      pure a
    EnemyEvaded iid eid | eid == enemyId -> do
      lid <- getJustLocation iid
      pure $ a & placementL .~ AtLocation lid & exhaustedL .~ True
    TryEvadeEnemy iid eid source mTarget skillType | eid == enemyId -> do
      mEnemyEvade' <- modifiedEnemyEvade a
      case mEnemyEvade' of
        Just n -> push $ BeginSkillTest
          iid
          source
          (maybe (EnemyTarget eid) (ProxyTarget (EnemyTarget eid)) mTarget)
          (Just Action.Evade)
          skillType
          n
        Nothing -> error "No evade value"
      pure a
    PassedSkillTest iid (Just Action.Evade) source (SkillTestInitiatorTarget target) _ n
      | isActionTarget a target
      -> do
        whenWindow <- checkWindows
          [Window Timing.When (Window.SuccessfulEvadeEnemy iid enemyId n)]
        afterWindow <- checkWindows
          [Window Timing.After (Window.SuccessfulEvadeEnemy iid enemyId n)]
        a <$ pushAll
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
      | isTarget a target
      -> do
        keywords <- getModifiedKeywords a
        whenWindow <- checkWindows
          [Window Timing.When (Window.FailEvadeEnemy iid enemyId n)]
        afterWindow <- checkWindows
          [Window Timing.After (Window.FailEvadeEnemy iid enemyId n)]
        a <$ pushAll
          ([whenWindow, afterWindow]
          <> [ EnemyAttack iid enemyId enemyDamageStrategy RegularAttack
             | Keyword.Alert `elem` keywords
             ]
          )
    InitiateEnemyAttack iid eid attackType | eid == enemyId -> do
      push $ EnemyAttack iid eid enemyDamageStrategy attackType
      pure a
    EnemyAttack iid eid damageStrategy attackType | eid == enemyId -> do
      whenAttacksWindow <- checkWindows
        [Window Timing.When (Window.EnemyAttacks iid eid attackType)]
      afterAttacksEventIfCancelledWindow <- checkWindows
        [ Window
            Timing.After
            (Window.EnemyAttacksEvenIfCancelled iid eid attackType)
        ]
      whenWouldAttackWindow <- checkWindows
        [Window Timing.When (Window.EnemyWouldAttack iid eid attackType)]
      a <$ pushAll
        [ whenWouldAttackWindow
        , whenAttacksWindow
        , PerformEnemyAttack iid eid damageStrategy attackType
        , After (PerformEnemyAttack iid eid damageStrategy attackType)
        , afterAttacksEventIfCancelledWindow
        ]
    PerformEnemyAttack iid eid damageStrategy attackType | eid == enemyId -> do
      modifiers <- getModifiers (InvestigatorTarget iid)
      let
        validEnemyMatcher = foldl' applyModifiers AnyEnemy modifiers
        applyModifiers m (CancelAttacksByEnemies n) = m <> (NotEnemy n)
        applyModifiers m _ = m
      allowAttack <- member enemyId <$> select validEnemyMatcher
      pushAll
        $ [ InvestigatorAssignDamage
              iid
              (EnemyAttackSource enemyId)
              damageStrategy
              enemyHealthDamage
              enemySanityDamage
          | allowAttack
          ]
        <> [After (EnemyAttack iid enemyId damageStrategy attackType)]
      pure a
    HealDamage (EnemyTarget eid) n | eid == enemyId ->
      pure $ a & damageL %~ max 0 . subtract n
    HealAllDamage (EnemyTarget eid) | eid == enemyId -> pure $ a & damageL .~ 0
    Msg.EnemyDamage eid damageAssignment | eid == enemyId -> do
      let
        source = damageAssignmentSource damageAssignment
        damageEffect = damageAssignmentDamageEffect damageAssignment
      canDamage <- sourceCanDamageEnemy eid source
      when
        canDamage
        do
          dealtDamageWhenMsg <- checkWindows
            [ Window
                Timing.When
                (Window.DealtDamage source damageEffect $ toTarget a)
            ]
          dealtDamageAfterMsg <- checkWindows
            [ Window
                Timing.After
                (Window.DealtDamage source damageEffect $ toTarget a)
            ]
          takeDamageWhenMsg <- checkWindows
            [ Window
                Timing.When
                (Window.TakeDamage source damageEffect $ toTarget a)
            ]
          takeDamageAfterMsg <- checkWindows
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
              damageAssignment { damageAssignmentAmount = amount' }
            combine l r =
              if damageAssignmentDamageEffect l
                == damageAssignmentDamageEffect r
              then
                l
                  { damageAssignmentAmount = damageAssignmentAmount l
                    + damageAssignmentAmount r
                  }
              else
                error
                $ "mismatched damage assignments\n\nassignment: "
                <> show l
                <> "\nnew assignment: "
                <> show r
          unless (damageAssignmentDelayed damageAssignment')
            $ push
            $ CheckDefeated source
          pure
            $ a
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
              when (a ^. damageL + amount' >= modifiedHealth) $ do
                let excess = (a ^. damageL + amount') - modifiedHealth
                whenMsg <- checkWindows
                  [Window Timing.When (Window.EnemyWouldBeDefeated eid)]
                afterMsg <- checkWindows
                  [Window Timing.After (Window.EnemyWouldBeDefeated eid)]
                whenExcessMsg <- checkWindows
                  [ Window
                      Timing.When
                      (Window.DealtExcessDamage
                        source
                        damageEffect
                        (EnemyTarget eid)
                        excess
                      )
                  | excess > 0
                  ]
                afterExcessMsg <- checkWindows
                  [ Window
                      Timing.After
                      (Window.DealtExcessDamage
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
                    (toCardCode a)
                    source
                    (setToList $ toTraits a)
                  ]
            pure $ a & damageL +~ amount' & assignedDamageL .~ mempty
    DefeatEnemy eid _ source | eid == enemyId -> do
      canBeDefeated <- withoutModifier a CannotBeDefeated
      modifiedHealth <- getModifiedHealth a
      canOnlyBeDefeatedByDamage <- hasModifier a CanOnlyBeDefeatedByDamage
      modifiers' <- getModifiers (toTarget a)
      let
        defeatedByDamage = a ^. damageL >= modifiedHealth
        canOnlyBeDefeatedByModifier = \case
          CanOnlyBeDefeatedBy source' -> First (Just source')
          _ -> First Nothing
        mOnlyBeDefeatedByModifier =
          getFirst $ foldMap canOnlyBeDefeatedByModifier modifiers'
        validDefeat =
          canBeDefeated
            && maybe True (== source) mOnlyBeDefeatedByModifier
            && (not canOnlyBeDefeatedByDamage || defeatedByDamage)
      when validDefeat $ push $ EnemyDefeated
        eid
        (toCardCode a)
        source
        (setToList $ toTraits a)
      pure a
    EnemyDefeated eid _ source _ | eid == toId a -> do
      miid <- getSourceController source
      whenMsg <- checkWindows
        [Window Timing.When (Window.EnemyDefeated miid eid)]
      afterMsg <- checkWindows
        [Window Timing.After (Window.EnemyDefeated miid eid)]
      let
        victory = cdVictoryPoints $ toCardDef a
        vengeance = cdVengeancePoints $ toCardDef a
        victoryMsgs =
          [ DefeatedAddToVictory $ toTarget a | isJust (victory <|> vengeance) ]
        defeatMsgs = if isJust (victory <|> vengeance)
          then resolve $ RemoveEnemy eid
          else [Discard $ toTarget a]

      withQueue_ $ mapMaybe (filterOutEnemyMessages eid)

      pushAll
        $ [whenMsg, When msg, After msg]
        <> victoryMsgs
        <> [afterMsg]
        <> defeatMsgs
      pure a
    Discard target | a `isTarget` target -> do
      windows' <- windows [Window.WouldBeDiscarded (toTarget a)]
      pushAll
        $ windows'
        <> [RemovedFromPlay $ toSource a, Discarded (toTarget a) (toCard a)]
      pure a
    PutOnTopOfDeck iid deck target | a `isTarget` target -> do
      pushAll
        $ resolve (RemoveEnemy $ toId a)
        <> [PutCardOnTopOfDeck iid deck (toCard a)]
      pure a
    PutOnBottomOfDeck iid deck target | a `isTarget` target -> do
      pushAll
        $ resolve (RemoveEnemy $ toId a)
        <> [PutCardOnBottomOfDeck iid deck (toCard a)]
      pure a
    RemovedFromPlay source | isSource a source -> do
      enemyAssets <- selectList $ EnemyAsset enemyId
      windowMsg <-
        checkWindows
        $ (`Window` Window.LeavePlay (toTarget a))
        <$> [Timing.When, Timing.After]
      pushAll
        $ windowMsg
        : map (Discard . AssetTarget) enemyAssets
        <> [ UnsealToken token | token <- enemySealedTokens ]
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
        push $ if Keyword.Massive `notElem` keywords && willMove
          then EnemyEntered enemyId lid
          else DisengageEnemy iid enemyId
      pure a
    CheckAttackOfOpportunity iid isFast | not isFast && not enemyExhausted -> do
      willAttack <- member iid <$> select (investigatorEngagedWith enemyId)
      when willAttack $ do
        modifiers' <- getModifiers (EnemyTarget enemyId)
        unless (CannotMakeAttacksOfOpportunity `elem` modifiers')
          $ push
          $ EnemyWillAttack iid enemyId enemyDamageStrategy AttackOfOpportunity
      pure a
    InvestigatorDrawEnemy iid eid | eid == enemyId -> do
      lid <- getJustLocation iid
      modifiers' <- getModifiers (EnemyTarget enemyId)
      let
        getModifiedSpawnAt [] = enemySpawnAt
        getModifiedSpawnAt (ForceSpawnLocation m : _) = Just $ SpawnLocation m
        getModifiedSpawnAt (_ : xs) = getModifiedSpawnAt xs
        spawnAtMatcher = getModifiedSpawnAt modifiers'
      case spawnAtMatcher of
        Nothing -> pushAll (resolve (EnemySpawn (Just iid) lid eid))
        Just matcher -> spawnAt enemyId matcher
      pure a
    EnemySpawnAtLocationMatching miid locationMatcher eid | eid == enemyId -> do
      lids <- selectList locationMatcher
      leadInvestigatorId <- getLeadInvestigatorId
      case lids of
        [] ->
          pushAll
            $ Discard (EnemyTarget eid)
            : [ Surge iid (toSource a)
              | iid <- maybeToList miid
              , enemySurgeIfUnabledToSpawn
              ]
        [lid] -> pushAll (resolve $ EnemySpawn miid lid eid)
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
    AdvanceAgenda{} -> pure $ a & doomL .~ 0
    RemoveAllClues target | isTarget a target -> pure $ a & cluesL .~ 0
    RemoveAllDoom target | isTarget a target -> pure $ a & doomL .~ 0
    PlaceDamage target amount | isTarget a target ->
      pure $ a & damageL +~ amount
    PlaceDoom target amount | isTarget a target -> do
      modifiers' <- getModifiers (toTarget a)
      if CannotPlaceDoomOnThis `elem` modifiers'
        then pure a
        else do
          windows' <- windows [Window.PlacedDoom (toTarget a) amount]
          pushAll windows'
          pure $ a & doomL +~ amount
    RemoveDoom target amount | isTarget a target ->
      pure $ a & doomL %~ max 0 . subtract amount
    PlaceClues target n | isTarget a target -> do
      windows' <- windows [Window.PlacedClues (toTarget a) n]
      pushAll windows'
      pure $ a & cluesL +~ n
    PlaceResources target n | isTarget a target -> do
      pure $ a & resourcesL +~ n
    RemoveClues target n | isTarget a target ->
      pure $ a & cluesL %~ max 0 . subtract n
    FlipClues target n | isTarget a target -> do
      let flipCount = min n enemyClues
      pure $ a & cluesL %~ max 0 . subtract n & doomL +~ flipCount
    PlaceEnemyInVoid eid | eid == enemyId -> do
      withQueue_ $ mapMaybe (filterOutEnemyMessages eid)
      pure
        $ a
        & (damageL .~ 0)
        & (placementL .~ TheVoid)
        & (exhaustedL .~ False)
        & (doomL .~ 0)
        & (cluesL .~ 0)
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

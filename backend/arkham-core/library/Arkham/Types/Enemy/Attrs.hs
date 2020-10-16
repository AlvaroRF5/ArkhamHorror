{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Attrs where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import Arkham.Types.Enemy.Runner
import Arkham.Types.Game.Helpers
import Arkham.Types.Keyword (Keyword)
import qualified Arkham.Types.Keyword as Keyword
import Arkham.Types.Prey
import Arkham.Types.Trait

data Attrs = Attrs
  { enemyName :: Text
  , enemyId :: EnemyId
  , enemyCardCode :: CardCode
  , enemyEngagedInvestigators :: HashSet InvestigatorId
  , enemyLocation :: LocationId
  , enemyFight :: Int
  , enemyHealth :: GameValue Int
  , enemyEvade :: Int
  , enemyDamage :: Int
  , enemyHealthDamage :: Int
  , enemySanityDamage :: Int
  , enemyTraits :: HashSet Trait
  , enemyTreacheries :: HashSet TreacheryId
  , enemyVictory :: Maybe Int
  , enemyKeywords :: HashSet Keyword
  , enemyPrey :: Prey
  , enemyModifiers :: HashMap Source [Modifier]
  , enemyExhausted :: Bool
  , enemyDoom :: Int
  }
  deriving stock (Show, Generic)

instance ToJSON Attrs where
  toJSON = genericToJSON $ aesonOptions $ Just "enemy"
  toEncoding = genericToEncoding $ aesonOptions $ Just "enemy"

instance FromJSON Attrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "enemy"

doom :: Lens' Attrs Int
doom = lens enemyDoom $ \m x -> m { enemyDoom = x }

prey :: Lens' Attrs Prey
prey = lens enemyPrey $ \m x -> m { enemyPrey = x }

engagedInvestigators :: Lens' Attrs (HashSet InvestigatorId)
engagedInvestigators =
  lens enemyEngagedInvestigators $ \m x -> m { enemyEngagedInvestigators = x }

location :: Lens' Attrs LocationId
location = lens enemyLocation $ \m x -> m { enemyLocation = x }

damage :: Lens' Attrs Int
damage = lens enemyDamage $ \m x -> m { enemyDamage = x }

health :: Lens' Attrs (GameValue Int)
health = lens enemyHealth $ \m x -> m { enemyHealth = x }

fight :: Lens' Attrs Int
fight = lens enemyFight $ \m x -> m { enemyFight = x }

evade :: Lens' Attrs Int
evade = lens enemyEvade $ \m x -> m { enemyEvade = x }

keywords :: Lens' Attrs (HashSet Keyword)
keywords = lens enemyKeywords $ \m x -> m { enemyKeywords = x }

modifiers :: Lens' Attrs (HashMap Source [Modifier])
modifiers = lens enemyModifiers $ \m x -> m { enemyModifiers = x }

treacheries :: Lens' Attrs (HashSet TreacheryId)
treacheries = lens enemyTreacheries $ \m x -> m { enemyTreacheries = x }

exhausted :: Lens' Attrs Bool
exhausted = lens enemyExhausted $ \m x -> m { enemyExhausted = x }

baseAttrs :: EnemyId -> CardCode -> Attrs
baseAttrs eid cardCode =
  let
    MkEncounterCard {..} =
      fromJustNote
          ("missing enemy encounter card: " <> show cardCode)
          (lookup cardCode allEncounterCards)
        $ CardId (unEnemyId eid)
  in
    Attrs
      { enemyName = ecName
      , enemyId = eid
      , enemyCardCode = cardCode
      , enemyEngagedInvestigators = mempty
      , enemyLocation = "00000" -- no known location
      , enemyFight = 1
      , enemyHealth = Static 1
      , enemyEvade = 1
      , enemyDamage = 0
      , enemyHealthDamage = 0
      , enemySanityDamage = 0
      , enemyTraits = setFromList ecTraits
      , enemyTreacheries = mempty
      , enemyKeywords = setFromList ecKeywords
      , enemyPrey = AnyPrey
      , enemyModifiers = mempty
      , enemyExhausted = False
      , enemyDoom = 0
      , enemyVictory = ecVictoryPoints
      }

weaknessBaseAttrs :: EnemyId -> CardCode -> Attrs
weaknessBaseAttrs eid cardCode =
  let
    MkPlayerCard {..} =
      fromJustNote
          ("missing player enemy weakness card: " <> show cardCode)
          (lookup cardCode allPlayerCards)
        $ CardId (unEnemyId eid)
  in
    Attrs
      { enemyName = pcName
      , enemyId = eid
      , enemyCardCode = cardCode
      , enemyEngagedInvestigators = mempty
      , enemyLocation = "00000" -- no known location
      , enemyFight = 1
      , enemyHealth = Static 1
      , enemyEvade = 1
      , enemyDamage = 0
      , enemyHealthDamage = 0
      , enemySanityDamage = 0
      , enemyTraits = pcTraits
      , enemyTreacheries = mempty
      , enemyVictory = pcVictoryPoints
      , enemyKeywords = setFromList pcKeywords
      , enemyPrey = AnyPrey
      , enemyModifiers = mempty
      , enemyExhausted = False
      , enemyDoom = 0
      }

spawnAtEmptyLocation
  :: (MonadIO m, HasSet EmptyLocationId () env, MonadReader env m, HasQueue env)
  => InvestigatorId
  -> EnemyId
  -> m ()
spawnAtEmptyLocation iid eid = do
  emptyLocations <- asks $ map unEmptyLocationId . setToList . getSet ()
  case emptyLocations of
    [] -> unshiftMessage (Discard (EnemyTarget eid))
    [lid] -> unshiftMessage (EnemySpawn lid eid)
    lids ->
      unshiftMessage (Ask iid $ ChooseOne [ EnemySpawn lid eid | lid <- lids ])

spawnAt
  :: (MonadIO m, HasSet LocationId () env, MonadReader env m, HasQueue env)
  => EnemyId
  -> LocationId
  -> m ()
spawnAt eid lid = do
  locations' <- asks (getSet ())
  if lid `elem` locations'
    then unshiftMessage (EnemySpawn lid eid)
    else unshiftMessage (Discard (EnemyTarget eid))

spawnAtOneOf
  :: (MonadIO m, HasSet LocationId () env, MonadReader env m, HasQueue env)
  => InvestigatorId
  -> EnemyId
  -> [LocationId]
  -> m ()
spawnAtOneOf iid eid targetLids = do
  locations' <- asks (getSet ())
  case setToList (setFromList targetLids `intersection` locations') of
    [] -> unshiftMessage (Discard (EnemyTarget eid))
    [lid] -> unshiftMessage (EnemySpawn lid eid)
    lids ->
      unshiftMessage (Ask iid $ ChooseOne [ EnemySpawn lid eid | lid <- lids ])

modifiedEnemyFight :: Attrs -> Int
modifiedEnemyFight Attrs {..} = foldr
  applyModifier
  enemyFight
  (concat . toList $ enemyModifiers)
 where
  applyModifier (EnemyFight m) n = max 0 (n + m)
  applyModifier _ n = n

modifiedEnemyEvade :: Attrs -> Int
modifiedEnemyEvade Attrs {..} = foldr
  applyModifier
  enemyEvade
  (concat . toList $ enemyModifiers)
 where
  applyModifier (EnemyEvade m) n = max 0 (n + m)
  applyModifier _ n = n

modifiedDamageAmount :: Attrs -> Int -> Int
modifiedDamageAmount attrs baseAmount = foldr
  applyModifier
  baseAmount
  (concat . toList $ enemyModifiers attrs)
 where
  applyModifier (DamageTaken m) n = max 0 (n + m)
  applyModifier _ n = n

canEnterLocation
  :: (EnemyRunner env, MonadReader env m, MonadIO m)
  => EnemyId
  -> LocationId
  -> m Bool
canEnterLocation eid lid = do
  traits <- asks (getSet eid)
  modifiers' <- getModifiers (EnemySource eid) lid
  pure $ not $ flip any modifiers' $ \case
    CannotBeEnteredByNonElite{} -> Elite `notMember` traits
    _ -> False

instance HasId EnemyId () Attrs where
  getId _ Attrs {..} = enemyId

instance IsEnemy Attrs where
  isAloof Attrs {..} = Keyword.Aloof `elem` enemyKeywords

instance (IsInvestigator investigator) => HasActions env investigator Attrs where
  getActions i NonFast enemy@Attrs {..} =
    pure $ fightEnemyActions <> engageEnemyActions <> evadeEnemyActions
   where
    investigatorId = getId () i
    locationId = locationOf i
    fightEnemyActions =
      [ FightEnemy
          investigatorId
          enemyId
          (InvestigatorSource investigatorId)
          SkillCombat
          []
          mempty
          True
      | enemyLocation == locationId && canFight enemy i
      ]
    engageEnemyActions =
      [ EngageEnemy investigatorId enemyId True
      | enemyLocation == locationId && canEngage enemy i
      ]
    evadeEnemyActions =
      [ EvadeEnemy
          investigatorId
          enemyId
          (InvestigatorSource investigatorId)
          SkillAgility
          mempty
          mempty
          mempty
          True
      | canEvade enemy i
      ]
  getActions _ _ _ = pure []

isTarget :: Attrs -> Target -> Bool
isTarget Attrs { enemyId } (EnemyTarget eid) = enemyId == eid
isTarget _ _ = False

instance EnemyRunner env => RunMessage env Attrs where
  runMessage msg a@Attrs {..} = case msg of
    EnemySpawnEngagedWithPrey eid | eid == enemyId -> do
      preyIds <- asks $ map unPreyId . setToList . getSet enemyPrey
      preyIdsWithLocation <- for preyIds
        $ \iid -> (iid, ) <$> asks (getId @LocationId iid)
      leadInvestigatorId <- getLeadInvestigatorId
      a <$ case preyIdsWithLocation of
        [] -> pure ()
        [(iid, lid)] -> unshiftMessages
          [EnemySpawnedAt lid eid, EnemyEngageInvestigator eid iid]
        iids -> unshiftMessage
          (Ask leadInvestigatorId $ ChooseOne
            [ Run [EnemySpawnedAt lid eid, EnemyEngageInvestigator eid iid]
            | (iid, lid) <- iids
            ]
          )
    EnemySpawn lid eid | eid == enemyId -> do
      when
          (Keyword.Aloof
          `notElem` enemyKeywords
          && Keyword.Massive
          `notElem` enemyKeywords
          )
        $ do
            preyIds <- asks $ map unPreyId . setToList . getSet (enemyPrey, lid)
            investigatorIds <- if null preyIds
              then getInvestigatorIds
              else pure []
            leadInvestigatorId <- getLeadInvestigatorId
            case preyIds <> investigatorIds of
              [] -> pure ()
              [iid] -> unshiftMessage (EnemyEngageInvestigator eid iid)
              iids -> unshiftMessage
                (Ask leadInvestigatorId $ ChooseOne
                  [ EnemyEngageInvestigator eid iid | iid <- iids ]
                )
      when (Keyword.Massive `elem` enemyKeywords) $ do
        investigatorIds <- getInvestigatorIds
        unshiftMessages
          [ EnemyEngageInvestigator eid iid | iid <- investigatorIds ]
      pure $ a & location .~ lid
    EnemySpawnedAt lid eid | eid == enemyId -> pure $ a & location .~ lid
    ReadyExhausted -> do
      miid <- asks $ headMay . setToList . getSet enemyLocation
      case miid of
        Just iid ->
          when
              (null enemyEngagedInvestigators
              || Keyword.Massive
              `elem` enemyKeywords
              )
            $ unshiftMessage (EnemyEngageInvestigator enemyId iid)
        Nothing -> pure ()
      pure $ a & exhausted .~ False
    MoveUntil lid target | isTarget a target -> if lid == enemyLocation
      then pure a
      else do
        leadInvestigatorId <- getLeadInvestigatorId
        closestLocationIds <-
          asks $ map unClosestLocationId . setToList . getSet
            (enemyLocation, lid)
        a <$ unshiftMessages
          [ chooseOne
            leadInvestigatorId
            [ EnemyMove enemyId enemyLocation lid'
            | lid' <- closestLocationIds
            ]
          , MoveUntil lid target
          ]

    EnemyMove eid _ lid | eid == enemyId -> do
      willMove <- canEnterLocation eid lid
      if willMove then pure $ a & location .~ lid else pure a
    HuntersMove
      | Keyword.Hunter
        `elem` enemyKeywords
        && null enemyEngagedInvestigators
        && not enemyExhausted
      -> do
        closestLocationIds <-
          asks $ map unClosestLocationId . setToList . getSet
            (enemyLocation, enemyPrey)
        leadInvestigatorId <- getLeadInvestigatorId
        case closestLocationIds of
          [] -> pure a
          [lid] -> a <$ unshiftMessage (EnemyMove enemyId enemyLocation lid)
          ls -> a <$ unshiftMessage
            (Ask leadInvestigatorId $ ChooseOne $ map
              (EnemyMove enemyId enemyLocation)
              ls
            )
    EnemiesAttack
      | not (null enemyEngagedInvestigators) && not enemyExhausted -> do
        unshiftMessages $ map (`EnemyWillAttack` enemyId) $ setToList
          enemyEngagedInvestigators
        pure a
    AttackEnemy iid eid source skillType tempModifiers tokenResponses
      | eid == enemyId -> do
        let
          onFailure = if Keyword.Retaliate `elem` enemyKeywords
            then [EnemyAttack iid eid, FailedAttackEnemy iid eid]
            else [FailedAttackEnemy iid eid]
        a <$ unshiftMessage
          (BeginSkillTest
            iid
            source
            (EnemyTarget eid)
            (Just Action.Fight)
            skillType
            (modifiedEnemyFight a)
            [SuccessfulAttackEnemy iid eid, InvestigatorDamageEnemy iid eid]
            onFailure
            tempModifiers
            tokenResponses
          )
    EnemyEvaded iid eid | eid == enemyId ->
      pure $ a & engagedInvestigators %~ deleteSet iid & exhausted .~ True
    TryEvadeEnemy iid eid source skillType onSuccess onFailure skillTestModifiers tokenResponses
      | eid == enemyId
      -> do
        let
          onFailure' = if Keyword.Alert `elem` enemyKeywords
            then EnemyAttack iid eid : onFailure
            else onFailure
          onSuccess' = flip map onSuccess $ \case
            Damage EnemyJustEvadedTarget source' n ->
              EnemyDamage eid iid source' n
            msg' -> msg'
        a <$ unshiftMessage
          (BeginSkillTest
            iid
            source
            (EnemyTarget eid)
            (Just Action.Evade)
            skillType
            (modifiedEnemyEvade a)
            (EnemyEvaded iid eid : onSuccess')
            onFailure'
            skillTestModifiers
            tokenResponses
          )
    PerformEnemyAttack iid eid | eid == enemyId -> a <$ unshiftMessage
      (InvestigatorAssignDamage
        iid
        (EnemySource enemyId)
        enemyHealthDamage
        enemySanityDamage
      )
    EnemyDamage eid iid source amount | eid == enemyId -> do
      let amount' = modifiedDamageAmount a amount
      playerCount <- unPlayerCount <$> asks (getCount ())
      (a & damage +~ amount') <$ when
        (a ^. damage + amount' >= a ^. health . to (`fromGameValue` playerCount)
        )
        (unshiftMessage (EnemyDefeated eid iid enemyCardCode source))
    AddModifiers (EnemyTarget eid) source modifiers' | eid == enemyId -> do
      when (Blank `elem` modifiers')
        $ unshiftMessage (RemoveAllModifiersFrom (EnemySource eid))
      pure $ a & modifiers %~ insertWith (<>) source modifiers'
    RemoveAllModifiersOnTargetFrom (EnemyTarget eid) source | eid == enemyId ->
      do
        when (Blank `elem` fromMaybe [] (lookup source enemyModifiers))
          $ unshiftMessage (ApplyModifiers (EnemyTarget enemyId))
        pure $ a & modifiers %~ deleteMap source
    RemoveAllModifiersFrom source -> runMessage
      (RemoveAllModifiersOnTargetFrom (EnemyTarget enemyId) source)
      a
    EnemyEngageInvestigator eid iid | eid == enemyId ->
      pure $ a & engagedInvestigators %~ insertSet iid
    EngageEnemy iid eid False | eid == enemyId ->
      pure $ a & engagedInvestigators .~ singleton iid
    MoveTo iid lid | iid `elem` enemyEngagedInvestigators ->
      if Keyword.Massive `elem` enemyKeywords
        then pure a
        else do
          willMove <- canEnterLocation enemyId lid
          if willMove
            then pure $ a & location .~ lid
            else a <$ unshiftMessage (DisengageEnemy iid enemyId)
    AfterEnterLocation iid lid | lid == enemyLocation -> do
      when
          (null enemyEngagedInvestigators
          || Keyword.Massive
          `elem` enemyKeywords
          )
        $ unshiftMessage (EnemyEngageInvestigator enemyId iid)
      pure a
    CheckAttackOfOpportunity iid isFast
      | not isFast && iid `elem` enemyEngagedInvestigators && not enemyExhausted
      -> a <$ unshiftMessage (EnemyWillAttack iid enemyId)
    InvestigatorDrawEnemy _ lid eid | eid == enemyId -> do
      unshiftMessage (EnemySpawn lid eid)
      pure $ a & location .~ lid
    InvestigatorEliminated iid ->
      pure $ a & engagedInvestigators %~ deleteSet iid
    UnengageNonMatching iid traits
      | iid `elem` enemyEngagedInvestigators && null
        (setFromList traits `intersection` enemyTraits)
      -> a <$ unshiftMessage (DisengageEnemy iid enemyId)
    DisengageEnemy iid eid | eid == enemyId -> do
      pure $ a & engagedInvestigators %~ deleteSet iid
    EnemySetBearer eid bid | eid == enemyId -> pure $ a & prey .~ Bearer bid
    AdvanceAgenda{} -> pure $ a & doom .~ 0
    PlaceDoom (CardIdTarget cid) amount | unCardId cid == unEnemyId enemyId ->
      pure $ a & doom +~ amount
    PlaceDoom (EnemyTarget eid) amount | eid == enemyId ->
      pure $ a & doom +~ amount
    AttachTreachery tid (EnemyTarget eid) | eid == enemyId ->
      pure $ a & treacheries %~ insertSet tid
    Blanked msg' -> runMessage msg' a
    _ -> pure a

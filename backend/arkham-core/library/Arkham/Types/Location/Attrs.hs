{-# LANGUAGE PatternSynonyms #-}

module Arkham.Types.Location.Attrs
  ( module Arkham.Types.Location.Attrs
  , module X
  ) where

import Arkham.Prelude

import Arkham.Json
import Arkham.Location.Cards
import Arkham.Types.Ability
import Arkham.Types.Action (TakenAction(..))
import qualified Arkham.Types.Action as Action
import Arkham.Types.AssetId
import Arkham.Types.Card
import Arkham.Types.Card.CardDef as X
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Direction
import Arkham.Types.Exception
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Matcher hiding (EnemyDefeated, RevealLocation)
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Name
import Arkham.Types.Query
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Trait
import Arkham.Types.Window (Window(..))
import qualified Arkham.Types.Window as Window

class IsLocation a

pattern AfterFailedInvestigate :: InvestigatorId -> Target -> Message
pattern AfterFailedInvestigate iid target <-
  After (FailedSkillTest iid (Just Action.Investigate) _ target _ _)

pattern UseResign :: InvestigatorId -> Source -> Message
pattern UseResign iid source <- UseCardAbility iid source _ 99 _

pattern UseDrawCardUnderneath :: InvestigatorId -> Source -> Message
pattern UseDrawCardUnderneath iid source <- UseCardAbility iid source _ 100 _

type LocationCard a = CardBuilder LocationId a

data LocationAttrs = LocationAttrs
  { locationId :: LocationId
  , locationCardCode :: CardCode
  , locationLabel :: Text
  , locationRevealClues :: GameValue Int
  , locationClues :: Int
  , locationDoom :: Int
  , locationResources :: Int
  , locationShroud :: Int
  , locationRevealed :: Bool
  , locationInvestigators :: HashSet InvestigatorId
  , locationEnemies :: HashSet EnemyId
  , locationSymbol :: LocationSymbol
  , locationRevealedSymbol :: LocationSymbol
  , locationConnectedSymbols :: HashSet LocationSymbol
  , locationRevealedConnectedSymbols :: HashSet LocationSymbol
  , locationConnectedLocations :: HashSet LocationId
  , locationTreacheries :: HashSet TreacheryId
  , locationEvents :: HashSet EventId
  , locationAssets :: HashSet AssetId
  , locationDirections :: HashMap Direction LocationId
  , locationConnectsTo :: HashSet Direction
  , locationCardsUnderneath :: [Card]
  , locationCostToEnterUnrevealed :: Cost
  }
  deriving stock (Show, Eq, Generic)

symbolL :: Lens' LocationAttrs LocationSymbol
symbolL = lens locationSymbol $ \m x -> m { locationSymbol = x }

connectedSymbolsL :: Lens' LocationAttrs (HashSet LocationSymbol)
connectedSymbolsL =
  lens locationConnectedSymbols $ \m x -> m { locationConnectedSymbols = x }

costToEnterUnrevealedL :: Lens' LocationAttrs Cost
costToEnterUnrevealedL = lens locationCostToEnterUnrevealed
  $ \m x -> m { locationCostToEnterUnrevealed = x }

connectsToL :: Lens' LocationAttrs (HashSet Direction)
connectsToL = lens locationConnectsTo $ \m x -> m { locationConnectsTo = x }

revealedConnectedSymbolsL :: Lens' LocationAttrs (HashSet LocationSymbol)
revealedConnectedSymbolsL = lens locationRevealedConnectedSymbols
  $ \m x -> m { locationRevealedConnectedSymbols = x }

revealedSymbolL :: Lens' LocationAttrs LocationSymbol
revealedSymbolL =
  lens locationRevealedSymbol $ \m x -> m { locationRevealedSymbol = x }

labelL :: Lens' LocationAttrs Text
labelL = lens locationLabel $ \m x -> m { locationLabel = x }

treacheriesL :: Lens' LocationAttrs (HashSet TreacheryId)
treacheriesL = lens locationTreacheries $ \m x -> m { locationTreacheries = x }

eventsL :: Lens' LocationAttrs (HashSet EventId)
eventsL = lens locationEvents $ \m x -> m { locationEvents = x }

investigatorsL :: Lens' LocationAttrs (HashSet InvestigatorId)
investigatorsL =
  lens locationInvestigators $ \m x -> m { locationInvestigators = x }

enemiesL :: Lens' LocationAttrs (HashSet EnemyId)
enemiesL = lens locationEnemies $ \m x -> m { locationEnemies = x }

assetsL :: Lens' LocationAttrs (HashSet AssetId)
assetsL = lens locationAssets $ \m x -> m { locationAssets = x }

doomL :: Lens' LocationAttrs Int
doomL = lens locationDoom $ \m x -> m { locationDoom = x }

cluesL :: Lens' LocationAttrs Int
cluesL = lens locationClues $ \m x -> m { locationClues = x }

resourcesL :: Lens' LocationAttrs Int
resourcesL = lens locationResources $ \m x -> m { locationResources = x }

revealedL :: Lens' LocationAttrs Bool
revealedL = lens locationRevealed $ \m x -> m { locationRevealed = x }

connectedLocationsL :: Lens' LocationAttrs (HashSet LocationId)
connectedLocationsL =
  lens locationConnectedLocations $ \m x -> m { locationConnectedLocations = x }

directionsL :: Lens' LocationAttrs (HashMap Direction LocationId)
directionsL = lens locationDirections $ \m x -> m { locationDirections = x }

cardsUnderneathL :: Lens' LocationAttrs [Card]
cardsUnderneathL =
  lens locationCardsUnderneath $ \m x -> m { locationCardsUnderneath = x }

instance HasCardCode LocationAttrs where
  toCardCode = locationCardCode

instance HasCardDef LocationAttrs where
  toCardDef a = case lookup (locationCardCode a) allLocationCards of
    Just def -> def
    Nothing ->
      error $ "missing card def for location " <> show (locationCardCode a)

instance ToJSON LocationAttrs where
  toJSON = genericToJSON $ aesonOptions $ Just "location"
  toEncoding = genericToEncoding $ aesonOptions $ Just "location"

instance FromJSON LocationAttrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "location"

instance Entity LocationAttrs where
  type EntityId LocationAttrs = LocationId
  type EntityAttrs LocationAttrs = LocationAttrs
  toId = locationId
  toAttrs = id

instance Named LocationAttrs where
  toName l = if locationRevealed l
    then fromMaybe baseName (cdRevealedName $ toCardDef l)
    else baseName
    where baseName = toName (toCardDef l)

instance TargetEntity LocationAttrs where
  toTarget = LocationTarget . toId
  isTarget LocationAttrs { locationId } (LocationTarget lid) =
    locationId == lid
  isTarget attrs (SkillTestInitiatorTarget target) = isTarget attrs target
  isTarget _ _ = False

instance SourceEntity LocationAttrs where
  toSource = LocationSource . toId
  isSource LocationAttrs { locationId } (LocationSource lid) =
    locationId == lid
  isSource _ _ = False

instance IsCard LocationAttrs where
  toCardId = unLocationId . locationId

instance HasName env LocationAttrs where
  getName = pure . toName

instance HasId (Maybe LocationId) env (Direction, LocationAttrs) where
  getId (dir, LocationAttrs {..}) = pure $ lookup dir locationDirections

instance HasId LocationSymbol env LocationAttrs where
  getId = pure . locationSymbol

instance HasList UnderneathCard env LocationAttrs where
  getList = pure . map UnderneathCard . locationCardsUnderneath

unrevealed :: LocationAttrs -> Bool
unrevealed = not . locationRevealed

revealed :: LocationAttrs -> Bool
revealed = locationRevealed

location
  :: (LocationAttrs -> a)
  -> CardDef
  -> Int
  -> GameValue Int
  -> LocationSymbol
  -> [LocationSymbol]
  -> CardBuilder LocationId a
location f def shroud' revealClues symbol' connectedSymbols' =
  locationWith f def shroud' revealClues symbol' connectedSymbols' id

locationWithRevealedSideConnections
  :: (LocationAttrs -> a)
  -> CardDef
  -> Int
  -> GameValue Int
  -> LocationSymbol
  -> [LocationSymbol]
  -> LocationSymbol
  -> [LocationSymbol]
  -> CardBuilder LocationId a
locationWithRevealedSideConnections f def shroud' revealClues symbol' connectedSymbols' revealedSymbol' revealedConnectedSymbols'
  = locationWith
    f
    def
    shroud'
    revealClues
    symbol'
    connectedSymbols'
    ((revealedConnectedSymbolsL .~ setFromList revealedConnectedSymbols')
    . (revealedSymbolL .~ revealedSymbol')
    )

locationWith
  :: (LocationAttrs -> a)
  -> CardDef
  -> Int
  -> GameValue Int
  -> LocationSymbol
  -> [LocationSymbol]
  -> (LocationAttrs -> LocationAttrs)
  -> CardBuilder LocationId a
locationWith f def shroud' revealClues symbol' connectedSymbols' g =
  CardBuilder
    { cbCardCode = cdCardCode def
    , cbCardBuilder = \lid -> f . g $ LocationAttrs
      { locationId = lid
      , locationCardCode = toCardCode def
      , locationLabel = nameToLabel (cdName def)
      , locationRevealClues = revealClues
      , locationClues = 0
      , locationDoom = 0
      , locationResources = 0
      , locationShroud = shroud'
      , locationRevealed = False
      , locationInvestigators = mempty
      , locationEnemies = mempty
      , locationSymbol = symbol'
      , locationRevealedSymbol = symbol'
      , locationConnectedSymbols = setFromList connectedSymbols'
      , locationRevealedConnectedSymbols = setFromList connectedSymbols'
      , locationConnectedLocations = mempty
      , locationTreacheries = mempty
      , locationEvents = mempty
      , locationAssets = mempty
      , locationDirections = mempty
      , locationConnectsTo = mempty
      , locationCardsUnderneath = mempty
      , locationCostToEnterUnrevealed = ActionCost 1
      }
    }

locationEnemiesWithTrait
  :: (MonadReader env m, HasSet Trait env EnemyId)
  => LocationAttrs
  -> Trait
  -> m [EnemyId]
locationEnemiesWithTrait LocationAttrs { locationEnemies } trait =
  filterM (fmap (member trait) . getSet) (setToList locationEnemies)

locationInvestigatorsWithClues
  :: (MonadReader env m, HasCount ClueCount env InvestigatorId)
  => LocationAttrs
  -> m [InvestigatorId]
locationInvestigatorsWithClues LocationAttrs { locationInvestigators } =
  filterM
    (fmap ((> 0) . unClueCount) . getCount)
    (setToList locationInvestigators)

getModifiedShroudValueFor
  :: (MonadReader env m, HasModifiersFor env ()) => LocationAttrs -> m Int
getModifiedShroudValueFor attrs = do
  modifiers' <- getModifiers (toSource attrs) (toTarget attrs)
  pure $ foldr applyModifier (locationShroud attrs) modifiers'
 where
  applyModifier (ShroudModifier m) n = max 0 (n + m)
  applyModifier _ n = n

getInvestigateAllowed
  :: (MonadReader env m, HasModifiersFor env ())
  => InvestigatorId
  -> LocationAttrs
  -> m Bool
getInvestigateAllowed iid attrs = do
  modifiers1' <- getModifiers (toSource attrs) (toTarget attrs)
  modifiers2' <- getModifiers (InvestigatorSource iid) (toTarget attrs)
  pure $ not (any isCannotInvestigate $ modifiers1' <> modifiers2')
 where
  isCannotInvestigate CannotInvestigate{} = True
  isCannotInvestigate _ = False

canEnterLocation
  :: (LocationRunner env, MonadReader env m) => EnemyId -> LocationId -> m Bool
canEnterLocation eid lid = do
  traits' <- getSet eid
  modifiers' <- getModifiers (EnemySource eid) (LocationTarget lid)
  pure $ not $ flip any modifiers' $ \case
    CannotBeEnteredByNonElite{} -> Elite `notMember` traits'
    _ -> False

withResignAction
  :: ( Entity location
     , EntityAttrs location ~ LocationAttrs
     , MonadReader env m
     , ActionRunner env
     , MonadIO m
     )
  => InvestigatorId
  -> Window
  -> location
  -> m [Ability]
withResignAction iid window@(Window Timing.When Window.NonFast) x
  | locationRevealed (toAttrs x) = withBaseActions iid window attrs
  $ pure [locationResignAction attrs]
  where attrs = toAttrs x
withResignAction iid window x = getAbilities iid window (toAttrs x)

locationResignAction :: LocationAttrs -> Ability
locationResignAction attrs = toLocationAbility attrs (resignAction attrs)

drawCardUnderneathLocationAction :: LocationAttrs -> Ability
drawCardUnderneathLocationAction attrs =
  toLocationAbility attrs (drawCardUnderneathAction attrs)

toLocationAbility :: LocationAttrs -> Ability -> Ability
toLocationAbility attrs ability = ability
  { abilityCriteria = Just
    (fromMaybe mempty (abilityCriteria ability)
    <> OnLocation (LocationWithId $ toId attrs)
    )
  }

locationAbility :: Ability -> Ability
locationAbility ability = case abilitySource ability of
  LocationSource lid -> ability
    { abilityCriteria = Just
      (fromMaybe mempty (abilityCriteria ability)
      <> OnLocation (LocationWithId lid)
      )
    }
  _ -> ability

withDrawCardUnderneathAction
  :: ( Entity location
     , EntityAttrs location ~ LocationAttrs
     , MonadReader env m
     , ActionRunner env
     , MonadIO m
     )
  => InvestigatorId
  -> Window
  -> location
  -> m [Ability]
withDrawCardUnderneathAction iid window@(Window Timing.When Window.NonFast) x
  | locationRevealed (toAttrs x) = withBaseActions iid window attrs $ pure
    [ drawCardUnderneathAction attrs
    | iid `on` attrs && locationClues attrs == 0
    ]
  where attrs = toAttrs x
withDrawCardUnderneathAction iid window x = getAbilities iid window (toAttrs x)

instance ActionRunner env => HasAbilities env LocationAttrs where
  getAbilities iid (Window Timing.When Window.NonFast) l@LocationAttrs {..} =
    do
      canMoveTo <- getCanMoveTo locationId iid
      investigateAllowed <- getInvestigateAllowed iid l
      modifiers' <- getModifiers (toSource l) (InvestigatorTarget iid)
      takenActions <- setFromList . map unTakenAction <$> getList iid
      pure
        $ moveActions modifiers' takenActions canMoveTo
        <> investigateActions investigateAllowed
   where
    costToEnter =
      if locationRevealed then ActionCost 1 else locationCostToEnterUnrevealed
    investigateActions investigateAllowed =
      [ restrictedAbility l 101 (OnLocation $ LocationWithId $ toId l)
          $ ActionAbility (Just Action.Investigate) (ActionCost 1)
      | investigateAllowed
      ]
    moveActions modifiers' takenActions canMoveTo =
      [ mkAbility l 102 $ ActionAbility
          (Just Action.Move)
          (foldl' (applyMoveCostModifiers takenActions) costToEnter modifiers')
      | canMoveTo
      ]
    applyMoveCostModifiers
      :: HashSet Action.Action -> Cost -> ModifierType -> Cost
    applyMoveCostModifiers takenActions costs (ActionCostOf actionTarget n) =
      case actionTarget of
        FirstOneOf as
          | Action.Move `elem` as && null
            (takenActions `intersect` setFromList as)
          -> increaseActionCost costs n
        IsAction Action.Move -> increaseActionCost costs n
        _ -> costToEnter
    applyMoveCostModifiers _ costs _ = costs
  getAbilities _ _ _ = pure []

getShouldSpawnNonEliteAtConnectingInstead
  :: (MonadReader env m, HasModifiersFor env ()) => LocationAttrs -> m Bool
getShouldSpawnNonEliteAtConnectingInstead attrs = do
  modifiers' <- getModifiers (toSource attrs) (toTarget attrs)
  pure $ flip any modifiers' $ \case
    SpawnNonEliteAtConnectingInstead{} -> True
    _ -> False

on :: InvestigatorId -> LocationAttrs -> Bool
on iid LocationAttrs { locationInvestigators } =
  iid `member` locationInvestigators

instance LocationRunner env => RunMessage env LocationAttrs where
  runMessage msg a@LocationAttrs {..} = case msg of
    Investigate iid lid source skillType False | lid == locationId -> do
      allowed <- getInvestigateAllowed iid a
      if allowed
        then do
          shroudValue' <- getModifiedShroudValueFor a
          a <$ push
            (BeginSkillTest
              iid
              source
              (LocationTarget lid)
              (Just Action.Investigate)
              skillType
              shroudValue'
            )
        else pure a
    PassedSkillTest iid (Just Action.Investigate) source (SkillTestInitiatorTarget target) _ _
      | isTarget a target
      -> a <$ push (SuccessfulInvestigation iid locationId source)
    SuccessfulInvestigation iid lid _ | lid == locationId -> do
      modifiers' <- getModifiers (InvestigatorSource iid) (LocationTarget lid)
      whenWindowMsgs <- checkWindows
        [Window Timing.When (Window.SuccessfulInvestigation iid lid)]
      afterWindowMsgs <- checkWindows
        [Window Timing.After (Window.SuccessfulInvestigation iid lid)]
      a <$ unless
        (AlternateSuccessfullInvestigation `elem` modifiers')
        (pushAll
        $ whenWindowMsgs
        <> [InvestigatorDiscoverClues iid lid 1 (Just Action.Investigate)]
        <> afterWindowMsgs
        )
    PlaceUnderneath target cards | isTarget a target ->
      pure $ a & cardsUnderneathL %~ (<> cards)
    SetLocationLabel lid label' | lid == locationId ->
      pure $ a & labelL .~ label'
    PlacedLocation _ _ lid | lid == locationId ->
      a <$ push (AddConnection lid locationSymbol)
    PlacedLocationDirection lid direction lid2 | lid == locationId ->
      case direction of
        LeftOf | RightOf `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid2)
            & (directionsL %~ insertMap RightOf lid2)
        RightOf | LeftOf `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid2)
            & (directionsL %~ insertMap LeftOf lid2)
        Above | Below `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid2)
            & (directionsL %~ insertMap Below lid2)
        Below | Above `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid2)
            & (directionsL %~ insertMap Above lid2)
        _ -> pure a
    PlacedLocationDirection lid direction lid2 | lid2 == locationId ->
      case direction of
        LeftOf | LeftOf `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid)
            & (directionsL %~ insertMap LeftOf lid)
        RightOf | RightOf `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid)
            & (directionsL %~ insertMap RightOf lid)
        Above | Above `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid)
            & (directionsL %~ insertMap Above lid)
        Below | Below `member` locationConnectsTo ->
          pure
            $ a
            & (connectedLocationsL %~ insertSet lid2)
            & (directionsL %~ insertMap Below lid2)
        _ -> pure a
    AttachTreachery tid (LocationTarget lid) | lid == locationId ->
      pure $ a & treacheriesL %~ insertSet tid
    AttachEvent eid (LocationTarget lid) | lid == locationId ->
      pure $ a & eventsL %~ insertSet eid
    Discard (AssetTarget aid) -> pure $ a & assetsL %~ deleteSet aid
    Discard (TreacheryTarget tid) -> pure $ a & treacheriesL %~ deleteSet tid
    Discard (EventTarget eid) -> pure $ a & eventsL %~ deleteSet eid
    Discard (EnemyTarget eid) -> pure $ a & enemiesL %~ deleteSet eid
    PlaceEnemyInVoid eid -> pure $ a & enemiesL %~ deleteSet eid
    RemoveFromGame (AssetTarget aid) -> pure $ a & assetsL %~ deleteSet aid
    RemoveFromGame (TreacheryTarget tid) ->
      pure $ a & treacheriesL %~ deleteSet tid
    RemoveFromGame (EventTarget eid) -> pure $ a & eventsL %~ deleteSet eid
    RemoveFromGame (EnemyTarget eid) -> pure $ a & enemiesL %~ deleteSet eid
    Discard target | isTarget a target ->
      a <$ pushAll (resolve (RemoveLocation $ toId a))
    AttachAsset aid (LocationTarget lid) | lid == locationId ->
      pure $ a & assetsL %~ insertSet aid
    AttachAsset aid _ -> pure $ a & assetsL %~ deleteSet aid
    AddConnection lid _ | lid == locationId -> do
      connectedLocations <- getSetList
        (if locationRevealed
          then locationRevealedConnectedSymbols
          else locationConnectedSymbols
        )
      pushAll $ map (AddedConnection locationId) connectedLocations
      pure $ a & connectedLocationsL %~ union (setFromList connectedLocations)
    AddConnection lid symbol' | lid /= locationId -> do
      let
        symbols = if locationRevealed
          then locationRevealedConnectedSymbols
          else locationConnectedSymbols
      if symbol' `elem` symbols
        then do
          push (AddedConnection locationId lid)
          pure $ a & connectedLocationsL %~ insertSet lid
        else pure a
    AddDirectConnection fromLid toLid | fromLid == locationId -> do
      pure $ a & connectedLocationsL %~ insertSet toLid
    DiscoverCluesAtLocation iid lid n maction | lid == locationId -> do
      let discoveredClues = min n locationClues
      checkWindowMsgs <- checkWindows
        [Window Timing.When (Window.DiscoverClues iid lid discoveredClues)]
      a <$ pushAll
        (checkWindowMsgs <> [DiscoverClues iid lid discoveredClues maction])
    AfterDiscoverClues iid lid n | lid == locationId -> do
      let lastClue = locationClues - n <= 0
      pushAll =<< checkWindows
        (Window Timing.After (Window.DiscoverClues iid lid n)
        : [ Window Timing.After (Window.DiscoveringLastClue iid lid)
          | lastClue
          ]
        )
      pure $ a & cluesL %~ max 0 . subtract n
    InvestigatorEliminated iid -> pure $ a & investigatorsL %~ deleteSet iid
    WhenEnterLocation iid lid
      | lid /= locationId && iid `elem` locationInvestigators
      -> pure $ a & investigatorsL %~ deleteSet iid -- TODO: should we broadcast leaving the location
    WhenEnterLocation iid lid | lid == locationId -> do
      unless locationRevealed $ push (RevealLocation (Just iid) lid)
      pure $ a & investigatorsL %~ insertSet iid
    SetLocationAsIf iid lid | lid == locationId -> do
      pure $ a & investigatorsL %~ insertSet iid
    SetLocationAsIf iid lid | lid /= locationId -> do
      pure $ a & investigatorsL %~ deleteSet iid
    AddToVictory (EnemyTarget eid) -> pure $ a & enemiesL %~ deleteSet eid
    EnemyEngageInvestigator eid iid -> do
      lid <- getId @LocationId iid
      if lid == locationId then pure $ a & enemiesL %~ insertSet eid else pure a
    EnemyMove eid fromLid lid | fromLid == locationId -> do
      willMove <- canEnterLocation eid lid
      pure $ if willMove then a & enemiesL %~ deleteSet eid else a
    EnemyMove eid _ lid | lid == locationId -> do
      willMove <- canEnterLocation eid lid
      pure $ if willMove then a & enemiesL %~ insertSet eid else a
    EnemyEntered eid lid | lid == locationId -> do
      pure $ a & enemiesL %~ insertSet eid
    EnemyEntered eid lid | lid /= locationId -> do
      pure $ a & enemiesL %~ deleteSet eid
    Will next@(EnemySpawn miid lid eid) | lid == locationId -> do
      shouldSpawnNonEliteAtConnectingInstead <-
        getShouldSpawnNonEliteAtConnectingInstead a
      when shouldSpawnNonEliteAtConnectingInstead $ do
        traits' <- getSetList eid
        when (Elite `notElem` traits') $ do
          activeInvestigatorId <- unActiveInvestigatorId <$> getId ()
          connectedLocationIds <- map unConnectedLocationId <$> getSetList lid
          availableLocationIds <-
            flip filterM connectedLocationIds $ \locationId' -> do
              modifiers' <- getModifiers
                (EnemySource eid)
                (LocationTarget locationId')
              pure . not $ flip any modifiers' $ \case
                SpawnNonEliteAtConnectingInstead{} -> True
                _ -> False
          withQueue_ $ filter (/= next)
          if null availableLocationIds
            then push (Discard (EnemyTarget eid))
            else push
              (chooseOne
                activeInvestigatorId
                [ Run
                    [Will (EnemySpawn miid lid' eid), EnemySpawn miid lid' eid]
                | lid' <- availableLocationIds
                ]
              )
      pure a
    EnemySpawn _ lid eid | lid == locationId ->
      pure $ a & enemiesL %~ insertSet eid
    EnemySpawnedAt lid eid | lid == locationId ->
      pure $ a & enemiesL %~ insertSet eid
    RemoveEnemy eid -> pure $ a & enemiesL %~ deleteSet eid
    EnemyDefeated eid _ _ _ _ _ -> pure $ a & enemiesL %~ deleteSet eid
    TakeControlOfAsset _ aid -> pure $ a & assetsL %~ deleteSet aid
    MoveAllCluesTo target | not (isTarget a target) -> do
      when (locationClues > 0) (push $ PlaceClues target locationClues)
      pure $ a & cluesL .~ 0
    PlaceClues target n | isTarget a target -> do
      modifiers' <- getModifiers (toSource a) (toTarget a)
      if CannotPlaceClues `elem` modifiers'
        then pure a
        else pure $ a & cluesL +~ n
    PlaceDoom target n | isTarget a target -> pure $ a & doomL +~ n
    PlaceResources target n | isTarget a target -> pure $ a & resourcesL +~ n
    RemoveClues (LocationTarget lid) n | lid == locationId ->
      pure $ a & cluesL %~ max 0 . subtract n
    RemoveAllClues target | isTarget a target -> pure $ a & cluesL .~ 0
    RevealLocation miid lid | lid == locationId -> do
      modifiers' <- getModifiers (toSource a) (toTarget a)
      locationClueCount <- if CannotPlaceClues `elem` modifiers'
        then pure 0
        else fromGameValue locationRevealClues . unPlayerCount <$> getCount ()
      windowMsgs <- checkWindows
        [ Window Timing.After (Window.RevealLocation iid lid)
        | iid <- maybeToList miid
        ]
      pushAll $ AddConnection lid locationRevealedSymbol : windowMsgs
      pure $ a & cluesL +~ locationClueCount & revealedL .~ True
    LookAtRevealed source target | isTarget a target -> do
      push (Label "Continue" [After (LookAtRevealed source target)])
      pure $ a & revealedL .~ True
    After (LookAtRevealed _ target) | isTarget a target ->
      pure $ a & revealedL .~ False
    RevealLocation _ lid | lid /= locationId ->
      if lid `notElem` toList (a ^. directionsL)
        then pure $ a & connectedLocationsL %~ deleteSet lid
        else pure a
    RemoveLocation lid ->
      pure $ a & connectedLocationsL %~ deleteSet lid & directionsL %~ filterMap
        (/= lid)
    UseResign iid source | isSource a source -> a <$ push (Resign iid)
    UseDrawCardUnderneath iid source | isSource a source ->
      case locationCardsUnderneath of
        (EncounterCard card : rest) -> do
          push (InvestigatorDrewEncounterCard iid card)
          pure $ a & cardsUnderneathL .~ rest
        _ -> throwIO $ InvalidState "Not expecting a player card or empty yet"
    Blanked msg' -> runMessage msg' a
    UseCardAbility iid source _ 101 _ | isSource a source ->
      a
        <$ push
             (Investigate
               iid
               (toId a)
               (InvestigatorSource iid)
               SkillIntellect
               False
             )
    UseCardAbility iid source _ 102 _ | isSource a source -> a <$ push
      (MoveAction
        iid
        locationId
        Free -- already paid by using ability
        True
      )
    _ -> pure a

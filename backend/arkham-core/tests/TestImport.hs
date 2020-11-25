{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
module TestImport
  ( module X
  , module TestImport
  )
where

import Arkham.Import as X
import Arkham.Types.Agenda as X
import qualified Arkham.Types.Agenda.Attrs as AgendaAttrs
import Arkham.Types.Asset as X
import qualified Arkham.Types.Asset.Attrs as Asset
import Arkham.Types.Card.PlayerCard (basePlayerCard)
import Arkham.Types.ChaosBag as X
import qualified Arkham.Types.ChaosBag as ChaosBag
import Arkham.Types.Difficulty
import Arkham.Types.Enemy as X
import qualified Arkham.Types.Enemy.Attrs as Enemy
import Arkham.Types.Event as X
import Arkham.Types.Game as X
import Arkham.Types.Game.Helpers as X
import Arkham.Types.Investigator as X
import qualified Arkham.Types.Investigator.Attrs as InvestigatorAttrs
import Arkham.Types.Location as X
import qualified Arkham.Types.Location.Attrs as Location
import qualified Arkham.Types.Location.Attrs as LocationAttrs
import Arkham.Types.Phase
import Arkham.Types.Scenario as X
import qualified Arkham.Types.Scenario.Attrs as ScenarioAttrs
import Arkham.Types.Stats as X
import Control.Monad.Fail as X
import Control.Monad.State hiding (replicateM)
import Control.Monad.State as X (get)
import qualified Data.HashMap.Strict as HashMap
import qualified Data.UUID as UUID
import Data.UUID.V4 as X
import Helpers.Matchers as X
import Helpers.Message as X
import Test.Hspec as X

testScenario
  :: MonadIO m
  => CardCode
  -> (ScenarioAttrs.Attrs -> ScenarioAttrs.Attrs)
  -> m Scenario
testScenario cardCode f =
  let name = unCardCode cardCode
  in pure $ baseScenario cardCode name [] [] Easy f

insertEntity
  :: (HasId k () v, Eq k, Hashable k) => v -> HashMap k v -> HashMap k v
insertEntity a = insertMap (getId a ()) a

buildEvent :: MonadIO m => CardCode -> Investigator -> m Event
buildEvent cardCode investigator = do
  eventId <- liftIO $ EventId <$> nextRandom
  pure $ lookupEvent cardCode (getInvestigatorId investigator) eventId

buildEnemy :: MonadIO m => CardCode -> m Enemy
buildEnemy cardCode = do
  enemyId <- liftIO $ EnemyId <$> nextRandom
  pure $ lookupEnemy cardCode enemyId

buildAsset :: MonadIO m => CardCode -> m Asset
buildAsset cardCode = do
  assetId <- liftIO $ AssetId <$> nextRandom
  pure $ lookupAsset cardCode assetId

testPlayerCards :: MonadIO m => Int -> m [PlayerCard]
testPlayerCards count' = replicateM count' (testPlayerCard id)

testPlayerCard :: MonadIO m => (PlayerCard -> PlayerCard) -> m PlayerCard
testPlayerCard f = do
  cardId <- CardId <$> liftIO nextRandom
  pure . f $ basePlayerCard cardId "asset" "Test" 0 AssetType Guardian

buildPlayerCard :: MonadIO m => CardCode -> m PlayerCard
buildPlayerCard cardCode = do
  cardId <- CardId <$> liftIO nextRandom
  pure $ lookupPlayerCard cardCode cardId

buildEncounterCard :: MonadIO m => CardCode -> m EncounterCard
buildEncounterCard cardCode = do
  cardId <- CardId <$> liftIO nextRandom
  pure $ lookupEncounterCard cardCode cardId

buildTestEnemyEncounterCard :: MonadIO m => m EncounterCard
buildTestEnemyEncounterCard = do
  cardId <- CardId <$> liftIO nextRandom
  pure $ lookupEncounterCard "enemy" cardId

buildTestTreacheryEncounterCard :: MonadIO m => m EncounterCard
buildTestTreacheryEncounterCard = do
  cardId <- CardId <$> liftIO nextRandom
  pure $ lookupEncounterCard "treachery" cardId

testEnemy :: MonadIO m => (Enemy.Attrs -> Enemy.Attrs) -> m Enemy
testEnemy f = do
  enemyId <- liftIO $ EnemyId <$> nextRandom
  pure $ baseEnemy enemyId "enemy" f

testAsset :: MonadIO m => (Asset.Attrs -> Asset.Attrs) -> m Asset
testAsset f = do
  assetId <- liftIO $ AssetId <$> nextRandom
  pure $ baseAsset assetId "asset" f

testAgenda
  :: MonadIO m
  => CardCode
  -> (AgendaAttrs.Attrs -> AgendaAttrs.Attrs)
  -> m Agenda
testAgenda cardCode f =
  pure $ baseAgenda (AgendaId cardCode) "Agenda" "1A" (Static 1) f

testLocation
  :: MonadIO m
  => CardCode
  -> (LocationAttrs.Attrs -> LocationAttrs.Attrs)
  -> m Location
testLocation cardCode f =
  let
    locationId = LocationId cardCode
    name = LocationName $ unCardCode cardCode
  in pure $ baseLocation locationId name 0 (Static 0) Square [] f

testInvestigator
  :: MonadIO m
  => CardCode
  -> (InvestigatorAttrs.Attrs -> InvestigatorAttrs.Attrs)
  -> m Investigator
testInvestigator cardCode f =
  let
    investigatorId = InvestigatorId cardCode
    name = unCardCode cardCode
    stats = Stats 5 5 5 5 5 5
  in pure $ baseInvestigator investigatorId name Neutral stats [] f

testConnectedLocations
  :: MonadIO m
  => (LocationAttrs.Attrs -> LocationAttrs.Attrs)
  -> (LocationAttrs.Attrs -> LocationAttrs.Attrs)
  -> m (Location, Location)
testConnectedLocations f1 f2 = do
  location1 <- testLocation
    "00000"
    (f1
    . (Location.symbol .~ Square)
    . (Location.revealedSymbol .~ Square)
    . (Location.connectedSymbols .~ setFromList [Triangle])
    . (Location.revealedConnectedSymbols .~ setFromList [Triangle])
    )
  location2 <- testLocation
    "00001"
    (f2
    . (Location.symbol .~ Triangle)
    . (Location.revealedSymbol .~ Triangle)
    . (Location.connectedSymbols .~ setFromList [Square])
    . (Location.revealedConnectedSymbols .~ setFromList [Square])
    )
  pure (location1, location2)

testUnconnectedLocations
  :: MonadIO m
  => (LocationAttrs.Attrs -> LocationAttrs.Attrs)
  -> (LocationAttrs.Attrs -> LocationAttrs.Attrs)
  -> m (Location, Location)
testUnconnectedLocations f1 f2 = do
  location1 <- testLocation
    "00000"
    (f1 . (Location.symbol .~ Square) . (Location.revealedSymbol .~ Square))
  location2 <- testLocation
    "00001"
    (f2 . (Location.symbol .~ Triangle) . (Location.revealedSymbol .~ Triangle))
  pure (location1, location2)

getActionsOf
  :: (HasActions GameInternal a, TestEntity a, MonadIO m)
  => GameExternal
  -> Investigator
  -> Window
  -> a
  -> m [Message]
getActionsOf game investigator window e = withGame
  game
  (getActions (getInvestigatorId investigator) window (updated game e))

chaosBagTokensOf :: Game queue -> [Token]
chaosBagTokensOf g = g ^. chaosBag . ChaosBag.chaosBagTokensLens

createMessageMatcher :: MonadIO m => Message -> m (IORef Bool, Message -> m ())
createMessageMatcher msg = do
  ref <- liftIO $ newIORef False
  pure (ref, \msg' -> when (msg == msg') (liftIO $ atomicWriteIORef ref True))

didPassSkillTestBy
  :: MonadIO m => Investigator -> Int -> m (IORef Bool, Message -> m ())
didPassSkillTestBy investigator n = createMessageMatcher
  (PassedSkillTest
    (getInvestigatorId investigator)
    Nothing
    TestSource
    (SkillTestInitiatorTarget TestTarget)
    n
  )

withGame :: MonadIO m => GameExternal -> ReaderT GameInternal m b -> m b
withGame game f = toInternalGame game >>= runReaderT f

runGameTestOnlyOption
  :: (MonadFail m, MonadIO m) => String -> Game [Message] -> m (Game [Message])
runGameTestOnlyOption reason game =
  runGameTestOnlyOptionWithLogger reason (pure . const ()) game

runGameTestOnlyOptionWithLogger
  :: (MonadFail m, MonadIO m)
  => String
  -> (Message -> m ())
  -> Game [Message]
  -> m (Game [Message])
runGameTestOnlyOptionWithLogger _reason logger game =
  case mapToList (gameQuestion game) of
    [(_, question)] -> case question of
      ChooseOne [msg] ->
        toInternalGame (game { gameMessages = msg : gameMessages game })
          >>= runMessages logger
      ChooseOneAtATime [msg] ->
        toInternalGame (game { gameMessages = msg : gameMessages game })
          >>= runMessages logger
      ChooseN _ [msg] ->
        toInternalGame (game { gameMessages = msg : gameMessages game })
          >>= runMessages logger
      _ -> error "spec expectation mismatch"
    _ -> error "There must be only one choice to use this function"

runGameTestFirstOption
  :: (MonadFail m, MonadIO m) => String -> Game [Message] -> m (Game [Message])
runGameTestFirstOption _reason game = case mapToList (gameQuestion game) of
  [(_, question)] -> case question of
    ChooseOne (msg : _) ->
      toInternalGame (game { gameMessages = msg : gameMessages game })
        >>= runMessages (pure . const ())
    ChooseOneAtATime (msg : _) ->
      toInternalGame (game { gameMessages = msg : gameMessages game })
        >>= runMessages (pure . const ())
    _ -> error "spec expectation mismatch"
  _ -> error "There must be at least one option"

runGameTestMessages
  :: (MonadFail m, MonadIO m)
  => Game [Message]
  -> [Message]
  -> m (Game [Message])
runGameTestMessages game msgs =
  toInternalGame (game { gameMessages = msgs <> gameMessages game })
    >>= runMessages (pure . const ())

runGameTestOptionMatching
  :: (MonadFail m, MonadIO m)
  => String
  -> (Message -> Bool)
  -> Game [Message]
  -> m (Game [Message])
runGameTestOptionMatching reason f game =
  runGameTestOptionMatchingWithLogger reason (pure . const ()) f game

runGameTestOptionMatchingWithLogger
  :: (MonadFail m, MonadIO m)
  => String
  -> (Message -> m ())
  -> (Message -> Bool)
  -> Game [Message]
  -> m (Game [Message])
runGameTestOptionMatchingWithLogger _reason logger f game =
  case mapToList (gameQuestion game) of
    [(_, question)] -> case question of
      ChooseOne msgs -> case find f msgs of
        Just msg ->
          toInternalGame (game { gameMessages = msg : gameMessages game })
            >>= runMessages logger
        Nothing -> error "could not find a matching message"
      _ -> error "unsupported questions type"
    _ -> error "There must be only one question to use this function"

runGameTest
  :: (MonadIO m, MonadFail m)
  => Investigator
  -> [Message]
  -> (GameInternal -> GameInternal)
  -> m GameExternal
runGameTest investigator queue f =
  runGameTestWithLogger (pure . const ()) investigator queue f

runGameTestWithLogger
  :: (MonadIO m, MonadFail m)
  => (Message -> m ())
  -> Investigator
  -> [Message]
  -> (GameInternal -> GameInternal)
  -> m GameExternal
runGameTestWithLogger logger investigator queue f =
  newGame investigator queue >>= runMessages logger . f

newGame :: MonadIO m => Investigator -> [Message] -> m GameInternal
newGame investigator queue = do
  ref <- newIORef queue
  history <- newIORef []
  roundHistory <- newIORef []
  pure $ Game
    { gameMessages = ref
    , gameMessageHistory = history
    , gameRoundMessageHistory = roundHistory
    , gameSeed = 1
    , gameCampaign = Nothing
    , gameScenario = Nothing
    , gamePlayerCount = 1
    , gameLocations = mempty
    , gameEnemies = mempty
    , gameAssets = mempty
    , gameInvestigators = HashMap.singleton investigatorId investigator
    , gamePlayers = HashMap.singleton 1 investigatorId
    , gameActiveInvestigatorId = investigatorId
    , gameLeadInvestigatorId = investigatorId
    , gamePhase = CampaignPhase -- TODO: maybe this should be a TestPhase or something?
    , gameEncounterDeck = mempty
    , gameDiscard = mempty
    , gameSkillTest = Nothing
    , gameAgendas = mempty
    , gameTreacheries = mempty
    , gameEvents = mempty
    , gameEffects = mempty
    , gameSkills = mempty
    , gameActs = mempty
    , gameChaosBag = emptyChaosBag
    , gameGameState = IsActive
    , gameUsedAbilities = mempty
    , gameFocusedCards = mempty
    , gameFocusedTokens = mempty
    , gameActiveCard = Nothing
    , gamePlayerOrder = [investigatorId]
    , gameVictoryDisplay = mempty
    , gameQuestion = mempty
    , gameHash = UUID.nil
    }
  where investigatorId = getInvestigatorId investigator

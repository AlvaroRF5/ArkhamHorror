{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

module TestImport
  ( module X
  , module TestImport
  ) where

import Arkham.Prelude as X

import qualified Arkham.Agenda.Cards as Cards
import qualified Arkham.Asset.Cards as Cards
import qualified Arkham.Enemy.Cards as Cards
import Arkham.Game as X hiding (newGame, runMessages)
import qualified Arkham.Game as Game
import qualified Arkham.Location.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Action
import Arkham.Types.Agenda as X
import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Cards.WhatsGoingOn
import Arkham.Types.AgendaId
import Arkham.Types.Asset as X
import Arkham.Types.Asset.Attrs hiding (body)
import Arkham.Types.Asset.Cards.Adaptable1
import Arkham.Types.AssetId
import Arkham.Types.Card as X
import qualified Arkham.Types.Card.CardDef as CardDef
import Arkham.Types.Card.EncounterCard as X
import Arkham.Types.Card.PlayerCard as X
import Arkham.Types.ChaosBag as X
import qualified Arkham.Types.ChaosBag as ChaosBag
import Arkham.Types.ClassSymbol
import Arkham.Types.Classes as X hiding
  (getCount, getId, getModifiers, getTokenValue)
import qualified Arkham.Types.Classes as Arkham
import Arkham.Types.Cost as X
import Arkham.Types.Difficulty
import Arkham.Types.Enemy as X
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Cards.SwarmOfRats
import Arkham.Types.Event as X
import Arkham.Types.Game as X hiding (getAsset)
import qualified Arkham.Types.Game as Game
import Arkham.Types.Game.Helpers as X hiding (getCanAffordCost)
import qualified Arkham.Types.Game.Helpers as Helpers
import Arkham.Types.GameValue as X
import Arkham.Types.Helpers as X
import Arkham.Types.Investigator as X
import Arkham.Types.Investigator.Attrs
import qualified Arkham.Types.Investigator.Attrs as Investigator
import Arkham.Types.Investigator.Cards.JennyBarnes
import Arkham.Types.InvestigatorId
import Arkham.Types.Location as X
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Cards.Study
import Arkham.Types.LocationId as X
import Arkham.Types.LocationSymbol
import Arkham.Types.Message as X
import Arkham.Types.Modifier
import Arkham.Types.Name
import Arkham.Types.Phase
import Arkham.Types.Query as X
import Arkham.Types.Scenario as X
import Arkham.Types.Scenario.Attrs
import Arkham.Types.SkillType as X
import Arkham.Types.Source as X
import Arkham.Types.Stats as X
import Arkham.Types.Target as X
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Token as X
import Arkham.Types.Window as X
  (Window(..), WindowType(DuringTurn, FastPlayerWindow, NonFast))
import Control.Lens as X (set, (^?!))
import Control.Monad.Fail as X
import Control.Monad.State as X (get)
import Control.Monad.State hiding (replicateM)
import qualified Data.HashMap.Strict as HashMap
import Data.These
import Data.UUID.V4 as X
import Helpers.Matchers as X
import Helpers.Message as X
import System.Random (StdGen, mkStdGen)
import Test.Hspec as X

runMessages
  :: ( MonadIO m
     , HasGameRef env
     , HasStdGen env
     , HasQueue env
     , MonadReader env m
     , HasMessageLogger env
     )
  => m ()
runMessages = Game.runMessages False

shouldSatisfyM
  :: (HasCallStack, Show a, MonadIO m) => m a -> (a -> Bool) -> m ()
x `shouldSatisfyM` y = liftIO . (`shouldSatisfy` y) =<< x

shouldMatchListM
  :: (HasCallStack, Show a, Eq a, MonadIO m) => m [a] -> [a] -> m ()
x `shouldMatchListM` y = liftIO . (`shouldMatchList` y) =<< x

refShouldBe :: (HasCallStack, Show a, Eq a, MonadIO m) => IORef a -> a -> m ()
ref `refShouldBe` y = do
  result <- liftIO $ readIORef ref
  liftIO $ result `shouldBe` y

nonFast :: Window
nonFast = Window Timing.When NonFast

fastPlayerWindow :: Window
fastPlayerWindow = Window Timing.When FastPlayerWindow

duringTurn :: InvestigatorId -> Window
duringTurn = Window Timing.When . DuringTurn

getId
  :: ( HasId id GameEnv a
     , HasGameRef env
     , HasQueue env
     , HasStdGen env
     , MonadReader env m
     , MonadIO m
     )
  => a
  -> m id
getId a = toGameEnv >>= runReaderT (Arkham.getId a)

getCount
  :: ( HasCount count GameEnv a
     , HasGameRef env
     , HasQueue env
     , HasStdGen env
     , MonadReader env m
     , MonadIO m
     )
  => a
  -> m count
getCount a = toGameEnv >>= runReaderT (Arkham.getCount a)

getAsset
  :: ( HasCallStack
     , MonadReader env m
     , HasGameRef env
     , MonadIO m
     , HasQueue env
     , HasStdGen env
     )
  => AssetId
  -> m Asset
getAsset aid = toGameEnv >>= runReaderT (Game.getAsset aid)

getTokenValue
  :: ( MonadReader env m
     , MonadIO m
     , HasGameRef env
     , HasQueue env
     , HasStdGen env
     , HasTokenValue GameEnv a
     )
  => a
  -> InvestigatorId
  -> TokenFace
  -> m TokenValue
getTokenValue a iid token =
  toGameEnv >>= runReaderT (Arkham.getTokenValue a iid token)

getCanAffordCost
  :: (MonadReader env m, HasGameRef env, HasQueue env, MonadIO m, HasStdGen env)
  => InvestigatorId
  -> Source
  -> Maybe Action
  -> Cost
  -> m Bool
getCanAffordCost iid source maction cost =
  toGameEnv >>= runReaderT (Helpers.getCanAffordCost iid source maction [] cost)

getModifiers
  :: (MonadReader env m, HasGameRef env, MonadIO m, HasQueue env, HasStdGen env)
  => Source
  -> Target
  -> m [ModifierType]
getModifiers s t = toGameEnv >>= runReaderT (Arkham.getModifiers s t)

data TestApp = TestApp
  { game :: IORef Game
  , messageQueueRef :: IORef [Message]
  , gen :: IORef StdGen
  , messageLogger :: Message -> IO ()
  }

newtype TestAppT m a = TestAppT { unTestAppT :: ReaderT TestApp m a }
  deriving newtype (MonadReader TestApp, Functor, Applicative, Monad, MonadTrans, MonadFail, MonadIO)

runTestApp :: TestApp -> TestAppT m a -> m a
runTestApp testApp = flip runReaderT testApp . unTestAppT

instance HasGameRef TestApp where
  gameRefL = lens game $ \m x -> m { game = x }

instance HasStdGen TestApp where
  genL = lens gen $ \m x -> m { gen = x }

instance HasQueue TestApp where
  messageQueue = lens messageQueueRef $ \m x -> m { messageQueueRef = x }

instance HasMessageLogger TestApp where
  messageLoggerL = lens messageLogger $ \m x -> m { messageLogger = x }

testScenario
  :: MonadIO m => CardCode -> (ScenarioAttrs -> ScenarioAttrs) -> m Scenario
testScenario cardCode f =
  let name = mkName $ unCardCode cardCode
  in pure $ baseScenario cardCode name [] [] Easy f

buildEvent :: MonadRandom m => CardCode -> Investigator -> m Event
buildEvent cardCode investigator =
  lookupEvent cardCode (toId investigator) <$> getRandom

buildEnemy :: MonadRandom m => CardCode -> m Enemy
buildEnemy cardCode = lookupEnemy cardCode <$> getRandom

buildAsset :: MonadRandom m => CardCode -> m Asset
buildAsset cardCode = lookupAsset cardCode <$> getRandom

testPlayerCards :: MonadRandom m => Int -> m [PlayerCard]
testPlayerCards count' = replicateM count' (testPlayerCard id)

testPlayerCard :: MonadRandom m => (CardDef -> CardDef) -> m PlayerCard
testPlayerCard f = genPlayerCard (f Cards.adaptable1) -- use adaptable because it has no in game effects

testEnemy :: MonadRandom m => (EnemyAttrs -> EnemyAttrs) -> m Enemy
testEnemy = testEnemyWithDef id

testWeaknessEnemy :: MonadRandom m => (EnemyAttrs -> EnemyAttrs) -> m Enemy
testWeaknessEnemy = testEnemyWithDef (CardDef.weaknessL .~ True)

testEnemyWithDef
  :: MonadRandom m
  => (CardDef -> CardDef)
  -> (EnemyAttrs -> EnemyAttrs)
  -> m Enemy
testEnemyWithDef defF attrsF =
  cbCardBuilder
      (SwarmOfRats'
      <$> enemyWith
            SwarmOfRats
            (defF Cards.swarmOfRats)
            (1, Static 1, 1)
            (0, 0)
            attrsF
      )
    <$> getRandom

testAsset :: MonadRandom m => (AssetAttrs -> AssetAttrs) -> m Asset
testAsset = testAssetWithDef id

testAssetWithDef
  :: MonadRandom m
  => (CardDef -> CardDef)
  -> (AssetAttrs -> AssetAttrs)
  -> m Asset
testAssetWithDef defF attrsF =
  cbCardBuilder
      (Adaptable1' <$> assetWith Adaptable1 (defF Cards.adaptable1) attrsF)
    <$> getRandom

testAgenda :: MonadIO m => CardCode -> (AgendaAttrs -> AgendaAttrs) -> m Agenda
testAgenda cardCode f = pure $ cbCardBuilder
  (WhatsGoingOn'
  <$> agendaWith (1, A) WhatsGoingOn Cards.whatsGoingOn (Static 100) f
  )
  (AgendaId cardCode)

testLocation :: MonadRandom m => (LocationAttrs -> LocationAttrs) -> m Location
testLocation = testLocationWithDef id

testLocationWithDef
  :: MonadRandom m
  => (CardDef -> CardDef)
  -> (LocationAttrs -> LocationAttrs)
  -> m Location
testLocationWithDef defF attrsF = do
  cbCardBuilder
      (Study'
      <$> locationWith Study (defF Cards.study) 0 (Static 0) Square [] attrsF
      )
    <$> getRandom

-- | We use Jenny Barnes because here abilities are the least
-- disruptive during tests since they won't add extra windows
-- or abilities
testInvestigator
  :: MonadIO m
  => CardCode
  -> (InvestigatorAttrs -> InvestigatorAttrs)
  -> m Investigator
testInvestigator cardCode f =
  let
    investigatorId = InvestigatorId cardCode
    name = mkName (unCardCode cardCode)
    stats = Stats 5 5 5 5 5 5
  in pure $ JennyBarnes' $ JennyBarnes $ f $ Investigator.baseAttrs
    investigatorId
    name
    Neutral
    stats
    []

testConnectedLocations
  :: MonadRandom m
  => (LocationAttrs -> LocationAttrs)
  -> (LocationAttrs -> LocationAttrs)
  -> m (Location, Location)
testConnectedLocations f1 f2 = testConnectedLocationsWithDef (id, f1) (id, f2)

testConnectedLocationsWithDef
  :: MonadRandom m
  => (CardDef -> CardDef, LocationAttrs -> LocationAttrs)
  -> (CardDef -> CardDef, LocationAttrs -> LocationAttrs)
  -> m (Location, Location)
testConnectedLocationsWithDef (defF1, attrsF1) (defF2, attrsF2) = do
  location1 <- testLocationWithDef
    defF1
    (attrsF1
    . (symbolL .~ Square)
    . (revealedSymbolL .~ Square)
    . (connectedSymbolsL .~ setFromList [Triangle])
    . (revealedConnectedSymbolsL .~ setFromList [Triangle])
    )
  location2 <- testLocationWithDef
    defF2
    (attrsF2
    . (symbolL .~ Triangle)
    . (revealedSymbolL .~ Triangle)
    . (connectedSymbolsL .~ setFromList [Square])
    . (revealedConnectedSymbolsL .~ setFromList [Square])
    )
  pure (location1, location2)

testUnconnectedLocations
  :: MonadRandom m
  => (LocationAttrs -> LocationAttrs)
  -> (LocationAttrs -> LocationAttrs)
  -> m (Location, Location)
testUnconnectedLocations f1 f2 = do
  location1 <- testLocation
    (f1 . (symbolL .~ Square) . (revealedSymbolL .~ Square))
  location2 <- testLocation
    (f2 . (symbolL .~ Triangle) . (revealedSymbolL .~ Triangle))
  pure (location1, location2)

getAbilitiesOf
  :: ( HasAbilities GameEnv a
     , TestEntity a
     , MonadIO m
     , MonadReader env m
     , HasStdGen env
     , HasGameRef env
     , HasQueue env
     )
  => Investigator
  -> Window
  -> a
  -> m [Ability]
getAbilitiesOf investigator window e = do
  e' <- updated e
  toGameEnv >>= runReaderT (getAbilities (toId investigator) window e')

getChaosBagTokens
  :: (HasGameRef env, MonadIO m, MonadReader env m) => m [TokenFace]
getChaosBagTokens =
  map tokenFace . view (chaosBagL . ChaosBag.tokensL) <$> getTestGame

createMessageMatcher :: MonadIO m => Message -> m (IORef Bool, Message -> m ())
createMessageMatcher msg = do
  ref <- liftIO $ newIORef False
  pure (ref, \msg' -> when (msg == msg') (liftIO $ atomicWriteIORef ref True))

didPassSkillTestBy
  :: MonadIO m
  => Investigator
  -> SkillType
  -> Int
  -> m (IORef Bool, Message -> m ())
didPassSkillTestBy investigator skillType n = createMessageMatcher
  (PassedSkillTest
    (toId investigator)
    Nothing
    (TestSource mempty)
    (SkillTestInitiatorTarget TestTarget)
    skillType
    n
  )

didFailSkillTestBy
  :: MonadIO m
  => Investigator
  -> SkillType
  -> Int
  -> m (IORef Bool, Message -> m ())
didFailSkillTestBy investigator skillType n = createMessageMatcher
  (FailedSkillTest
    (toId investigator)
    Nothing
    (TestSource mempty)
    (SkillTestInitiatorTarget TestTarget)
    skillType
    n
  )

withGame :: Game -> ReaderT Game m b -> m b
withGame = flip runReaderT

chooseOnlyOption
  :: ( MonadFail m
     , MonadIO m
     , HasQueue env
     , MonadReader env m
     , HasGameRef env
     , HasStdGen env
     , HasMessageLogger env
     , HasCallStack
     )
  => String
  -> m ()
chooseOnlyOption _reason = do
  questionMap <- gameQuestion <$> getTestGame
  case mapToList questionMap of
    [(_, question)] -> case question of
      ChooseOne [msg] -> push msg <* runMessages
      ChooseOneAtATime [msg] -> push msg <* runMessages
      ChooseN _ [msg] -> push msg <* runMessages
      _ -> error "spec expectation mismatch"
    _ -> error "There must be only one choice to use this function"

chooseFirstOption
  :: ( MonadFail m
     , MonadIO m
     , MonadReader env m
     , HasGameRef env
     , HasQueue env
     , HasStdGen env
     , HasMessageLogger env
     )
  => String
  -> m ()
chooseFirstOption _reason = do
  questionMap <- gameQuestion <$> getTestGame
  case mapToList questionMap of
    [(_, question)] -> case question of
      ChooseOne (msg : _) -> push msg >> runMessages
      ChooseOneAtATime (msg : _) -> push msg >> runMessages
      _ -> error "spec expectation mismatch"
    _ -> error "There must be at least one option"

chooseOptionMatching
  :: ( MonadFail m
     , MonadIO m
     , MonadReader env m
     , HasGameRef env
     , HasQueue env
     , HasStdGen env
     , HasMessageLogger env
     )
  => String
  -> (Message -> Bool)
  -> m ()
chooseOptionMatching _reason f = do
  questionMap <- gameQuestion <$> getTestGame
  case mapToList questionMap of
    [(_, question)] -> case question of
      ChooseOne msgs -> case find f msgs of
        Just msg -> push msg <* runMessages
        Nothing -> error "could not find a matching message"
      _ -> error "unsupported questions type"
    _ -> error "There must be only one question to use this function"

gameTest
  :: Investigator -> [Message] -> (Game -> Game) -> TestAppT IO () -> IO ()
gameTest = gameTestWithLogger (pure . const ())

gameTestWithLogger
  :: (Message -> IO ())
  -> Investigator
  -> [Message]
  -> (Game -> Game)
  -> TestAppT IO ()
  -> IO ()
gameTestWithLogger logger investigator queue f body = do
  g <- newGame investigator
  gameRef <- newIORef (f g)
  queueRef <- newIORef queue
  genRef <- newIORef $ mkStdGen (gameSeed g)
  runTestApp (TestApp gameRef queueRef genRef logger) body

newGame :: MonadIO m => Investigator -> m Game
newGame investigator = do
  scenario' <- testScenario "00000" id
  seed <- liftIO getRandom
  pure $ Game
    { gameParams = GameParams (Left "00000") 1 mempty Easy -- Not used in tests
    , gameWindowDepth = 0
    , gamePhaseHistory = mempty
    , gameRoundHistory = mempty
    , gameTurnPlayerInvestigatorId = Just investigatorId
    , gameSeed = seed
    , gameInitialSeed = seed
    , gameMode = That scenario'
    , gamePlayerCount = 1
    , gameLocations = mempty
    , gameEnemies = mempty
    , gameEnemiesInVoid = mempty
    , gameAssets = mempty
    , gameInvestigators = HashMap.singleton investigatorId investigator
    , gameActiveInvestigatorId = investigatorId
    , gameLeadInvestigatorId = investigatorId
    , gamePhase = CampaignPhase -- TODO: maybe this should be a TestPhase or something?
    , gameEncounterDeck = mempty
    , gameDiscard = mempty
    , gameSkillTest = Nothing
    , gameSkillTestResults = Nothing
    , gameAgendas = mempty
    , gameTreacheries = mempty
    , gameEvents = mempty
    , gameEffects = mempty
    , gameSkills = mempty
    , gameActs = mempty
    , gameChaosBag = emptyChaosBag
    , gameGameState = IsActive
    , gameResignedCardCodes = mempty
    , gameUsedAbilities = mempty
    , gameFocusedCards = mempty
    , gameFocusedTargets = mempty
    , gameFocusedTokens = mempty
    , gameActiveCard = Nothing
    , gamePlayerOrder = [investigatorId]
    , gameVictoryDisplay = mempty
    , gameRemovedFromPlay = mempty
    , gameQuestion = mempty
    }
  where investigatorId = toId investigator

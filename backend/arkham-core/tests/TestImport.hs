{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

module TestImport
  ( module X
  , module TestImport
  ) where

import Arkham.Prelude as X hiding (assert)

import Arkham.Ability
import Arkham.Projection
import Arkham.Action
import Arkham.Agenda as X
import Arkham.Agenda.Attrs
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Cards.WhatsGoingOn
import Arkham.AgendaId
import Arkham.Asset as X ( Asset (Adaptable1'), createAsset, lookupAsset )
import Arkham.Asset.Attrs
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Cards.Adaptable1
import Arkham.AssetId
import Arkham.Card as X
import Arkham.Card.CardDef qualified as CardDef
import Arkham.Card.EncounterCard as X
import Arkham.Card.PlayerCard as X
import Arkham.ChaosBag as X
import Arkham.ChaosBag qualified as ChaosBag
import Arkham.Classes as X hiding
  ( getCount, getId, getModifiers, getTokenValue )
import Arkham.Classes qualified as Arkham
import Arkham.Cost as X
import Arkham.Difficulty
import Arkham.Enemy as X
import Arkham.Enemy.Attrs
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Enemy.Cards.SwarmOfRats
import Arkham.Event as X
import Arkham.Game as X hiding ( getAsset, newGame, runMessages )
import Arkham.Game qualified as Game
import Arkham.Game.Helpers as X hiding ( getCanAffordCost )
import Arkham.Game.Helpers qualified as Helpers
import Arkham.GameValue as X
import Arkham.Helpers as X
import Arkham.Helpers.Modifiers as Arkham
import Arkham.Investigator as X
import Arkham.Investigator.Attrs hiding (investigator, assetsL)
import Arkham.Investigator.Attrs qualified as Investigator
import Arkham.Helpers.Investigator qualified as Investigator
import Arkham.Investigator.Cards.JennyBarnes
import Arkham.Investigator.Cards qualified as Cards
import Arkham.InvestigatorId
import Arkham.Location as X
import Arkham.Location.Attrs
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Cards.Study
import Arkham.LocationId as X
import Arkham.Matcher hiding ( DuringTurn, FastPlayerWindow )
import Arkham.Message as X
import Arkham.Modifier
import Arkham.Phase
import Arkham.Scenario as X
import Arkham.Scenario.Attrs
import Arkham.Scenario.Attrs qualified as Scenario
import Arkham.Scenario.Scenarios.TheGathering ( TheGathering (..) )
import Arkham.SkillType as X
import Arkham.Source as X
import Arkham.Stats as X
import Arkham.Target as X
import Arkham.Timing qualified as Timing
import Arkham.Token as X
import Arkham.Window as X
  ( Window (..), WindowType (DuringTurn, FastPlayerWindow, NonFast) )
import Control.Lens as X ( set, (^?!) )
import Control.Monad.Fail as X
import Control.Monad.State as X ( get )
import Control.Monad.State hiding ( replicateM )
import Data.HashMap.Strict qualified as HashMap
import Data.These
import Data.UUID.V4 as X
import Helpers.Message as X
import System.Random ( StdGen, mkStdGen )
import Test.Hspec as X

import Arkham.GameEnv
import Arkham.LocationSymbol
import Arkham.Agenda.Sequence
import Arkham.Name
import Data.IntMap.Strict qualified as IntMap
import Arkham.Entities as X

runMessages :: TestAppT ()
runMessages = asks testLogger >>= Game.runMessages

pushAndRun :: Message -> TestAppT ()
pushAndRun msg = push msg >> runMessages

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

data TestApp = TestApp
  { game :: IORef Game
  , messageQueueRef :: IORef [Message]
  , gen :: IORef StdGen
  , testLogger :: Maybe (Message -> IO ())
  , testGameLogger :: Text -> IO ()
  }

newtype TestAppT a = TestAppT { unTestAppT :: ReaderT TestApp IO a }
  deriving newtype (MonadReader TestApp, Functor, Applicative, Monad, MonadFail, MonadIO)

instance HasGame TestAppT where
  getGame = do
    env <- ask
    readIORef $ game env

runTestApp :: TestApp -> TestAppT a -> IO a
runTestApp testApp = flip runReaderT testApp . unTestAppT

instance HasGameRef TestApp where
  gameRefL = lens game $ \m x -> m { game = x }

instance HasStdGen TestApp where
  genL = lens gen $ \m x -> m { gen = x }

instance HasQueue TestApp where
  messageQueue = lens messageQueueRef $ \m x -> m { messageQueueRef = x }

instance HasGameLogger TestApp where
  gameLoggerL = lens testGameLogger $ \m x -> m { testGameLogger = x }

testScenario
  :: MonadIO m => CardCode -> (ScenarioAttrs -> ScenarioAttrs) -> m Scenario
testScenario cardCode f = do
  a1 <- testAgenda "01105" id
  let name = mkName $ unCardCode cardCode
  pure $ TheGathering' $ TheGathering $ f $ (Scenario.baseAttrs
    cardCode
    name
    Easy) { scenarioAgendaStack = IntMap.fromList [(1, [toCardDef (toAttrs a1), toCardDef (toAttrs a1)])] }

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
testWeaknessEnemy = testEnemyWithDef (CardDef.subTypeL ?~ Weakness)

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
  (1, AgendaId cardCode)

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
  => (InvestigatorAttrs -> InvestigatorAttrs)
  -> m Investigator
testInvestigator f = pure $ JennyBarnes' . ($ ()) . cbCardBuilder $ Investigator.investigator (JennyBarnes . f) Cards.jennyBarnes stats
 where
  stats = Stats 5 5 5 5 5 5

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
    . (connectedMatchersL .~ [LocationWithSymbol Triangle])
    . (revealedConnectedMatchersL .~ [LocationWithSymbol Triangle])
    )
  location2 <- testLocationWithDef
    defF2
    (attrsF2
    . (symbolL .~ Triangle)
    . (revealedSymbolL .~ Triangle)
    . (connectedMatchersL .~ [LocationWithSymbol Square])
    . (revealedConnectedMatchersL .~ [LocationWithSymbol Square])
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

assert :: TestAppT Bool -> TestAppT ()
assert body = do
  result <- body
  liftIO $ result `shouldBe` True

withGame :: (MonadReader env m, HasGame m, MonadIO m) => ReaderT Game m b -> m b
withGame b = do
  g <- getGame
  runReaderT b g

replaceScenario :: (MonadReader env m, HasGameRef env, MonadIO m) => (ScenarioAttrs -> ScenarioAttrs) -> m ()
replaceScenario f = do
  scenario' <- testScenario "00000" f
  ref <- view gameRefL
  atomicModifyIORef' ref (\g -> (g { gameMode = That scenario' }, ()))

chooseOnlyOption
  :: String
  -> TestAppT ()
chooseOnlyOption _reason = do
  questionMap <- gameQuestion <$> getGame
  case mapToList questionMap of
    [(_, question)] -> case question of
      ChooseOne [msg] -> push msg <* runMessages
      ChooseOneAtATime [msg] -> push msg <* runMessages
      ChooseN _ [msg] -> push msg <* runMessages
      _ -> error "spec expectation mismatch"
    _ -> error "There must be only one choice to use this function"

chooseFirstOption
  :: String
  -> TestAppT ()
chooseFirstOption _reason = do
  questionMap <- gameQuestion <$> getGame
  case mapToList questionMap of
    [(_, question)] -> case question of
      ChooseOne (msg : _) -> push msg >> runMessages
      ChooseOneAtATime (msg : _) -> push msg >> runMessages
      _ -> error "spec expectation mismatch"
    _ -> error "There must be at least one option"

chooseOptionMatching
  :: String
  -> (Message -> Bool)
  -> TestAppT ()
chooseOptionMatching _reason f = do
  questionMap <- gameQuestion <$> getGame
  case mapToList questionMap of
    [(_, question)] -> case question of
      ChooseOne msgs -> case find f msgs of
        Just msg -> push msg <* runMessages
        Nothing -> error "could not find a matching message"
      ChooseN _ msgs -> case find f msgs of
        Just msg -> push msg <* runMessages
        Nothing -> error "could not find a matching message"
      ChooseDynamicCardAmounts _ _ _ _ msgs -> case find f msgs of
        Just msg -> push msg <* runMessages
        Nothing -> error "could not find a matching message"
      _ -> error $ "unsupported questions type: " <> show question
    _ -> error "There must be only one question to use this function"

gameTest
  :: Investigator -> [Message] -> (Game -> Game) -> TestAppT () -> IO ()
gameTest = gameTestWithLogger (pure . const ())

gameTestWithLogger
  :: (Message -> IO ())
  -> Investigator
  -> [Message]
  -> (Game -> Game)
  -> TestAppT ()
  -> IO ()
gameTestWithLogger logger investigator queue f body = do
  g <- newGame investigator
  gameRef <- newIORef (f g)
  queueRef <- newIORef queue
  genRef <- newIORef $ mkStdGen (gameSeed g)
  runTestApp
    (TestApp gameRef queueRef genRef (Just logger) (pure . const ()))
    body

newGame :: MonadIO m => Investigator -> m Game
newGame investigator = do
  scenario' <- testScenario "00000" id
  seed <- liftIO getRandom
  pure $ Game
    { gameParams = GameParams (Left "00000") 1 mempty Easy -- Not used in tests
    , gameWindowDepth = 0
    , gameDepthLock = 0
    , gamePhaseHistory = mempty
    , gameRoundHistory = mempty
    , gameTurnHistory = mempty
    , gameTurnPlayerInvestigatorId = Just investigatorId
    , gameSeed = seed
    , gameInitialSeed = seed
    , gameMode = That scenario'
    , gamePlayerCount = 1
    , gameEnemiesInVoid = mempty
    , gameActiveInvestigatorId = investigatorId
    , gameLeadInvestigatorId = investigatorId
    , gamePhase = CampaignPhase -- TODO: maybe this should be a TestPhase or something?
    , gameSkillTest = Nothing
    , gameSkillTestResults = Nothing
    , gameEntities = defaultEntities { entitiesInvestigators = HashMap.singleton investigatorId investigator }
    , gameEncounterDiscardEntities = defaultEntities
    , gameInHandEntities = mempty
    , gameInDiscardEntities = mempty
    , gameInSearchEntities = defaultEntities
    , gameGameState = IsActive
    , gameFoundCards = mempty
    , gameFocusedCards = mempty
    , gameFocusedTargets = mempty
    , gameFocusedTokens = mempty
    , gameActiveCard = Nothing
    , gamePlayerOrder = [investigatorId]
    , gameRemovedFromPlay = mempty
    , gameEnemyMoving = Nothing
    , gameQuestion = mempty
    }
  where investigatorId = toId investigator

-- Helpers

isInDiscardOf :: (IsCard (EntityAttrs a), Entity a) => Investigator -> a -> TestAppT Bool
isInDiscardOf i a = do
  let Just pc = preview _PlayerCard (toCard $ toAttrs a)
  fieldP InvestigatorDiscard (elem pc) (toId i)

getRemainingActions :: Investigator -> TestAppT Int
getRemainingActions = field InvestigatorRemainingActions . toId

evadedBy :: Investigator -> Enemy -> TestAppT Bool
evadedBy _investigator = fieldP EnemyEngagedInvestigators null . toId

fieldAssert :: (Projection attrs, Entity a, EntityId a ~ EntityId attrs) => Field attrs typ -> (typ -> Bool) -> a -> TestAppT ()
fieldAssert fld p a = assert $ fieldP fld p (toId a)

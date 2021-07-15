module Arkham.Types.Scenario
  ( module Arkham.Types.Scenario
  ) where

import Arkham.Prelude

import Arkham.Types.ActId
import Arkham.Types.AgendaId
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Difficulty
import Arkham.Types.EnemyId
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.LocationMatcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Name
import Arkham.Types.Query
import Arkham.Types.Resolution
import Arkham.Types.Scenario.Attrs
import Arkham.Types.Scenario.Runner
import Arkham.Types.Scenario.Scenarios
import Arkham.Types.ScenarioId
import Arkham.Types.ScenarioLogKey
import Arkham.Types.Target
import Arkham.Types.Token
import Arkham.Types.Trait (Trait)

data Scenario
  = TheGathering' TheGathering
  | TheMidnightMasks' TheMidnightMasks
  | TheDevourerBelow' TheDevourerBelow
  | ExtracurricularActivity' ExtracurricularActivity
  | TheHouseAlwaysWins' TheHouseAlwaysWins
  | TheMiskatonicMuseum' TheMiskatonicMuseum
  | TheEssexCountyExpress' TheEssexCountyExpress
  | BloodOnTheAltar' BloodOnTheAltar
  | UndimensionedAndUnseen' UndimensionedAndUnseen
  | WhereDoomAwaits' WhereDoomAwaits
  | LostInTimeAndSpace' LostInTimeAndSpace
  | ReturnToTheGathering' ReturnToTheGathering
  | ReturnToTheMidnightMasks' ReturnToTheMidnightMasks
  | ReturnToTheDevourerBelow' ReturnToTheDevourerBelow
  | CurseOfTheRougarou' CurseOfTheRougarou
  | CarnevaleOfHorrors' CarnevaleOfHorrors
  | BaseScenario' BaseScenario
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, HasRecord)

instance
  ( HasModifiersFor env ()
  , HasId (Maybe LocationId) env LocationMatcher
  , HasStep env ActStep, ScenarioRunner env
  )
  => RunMessage env Scenario where
  runMessage msg s = case msg of
    ResolveToken _ tokenFace _ -> do
      modifiers' <-
        map modifierType
          <$> getModifiersFor
                (toSource $ toAttrs s)
                (TokenFaceTarget tokenFace)
                ()
      if IgnoreTokenEffects `elem` modifiers'
        then pure s
        else defaultRunMessage msg s
    FailedSkillTest _ _ _ (TokenTarget token) _ _ -> do
      modifiers' <-
        map modifierType
          <$> getModifiersFor
                (toSource $ toAttrs s)
                (TokenFaceTarget $ tokenFace token)
                ()
      if IgnoreTokenEffects `elem` modifiers'
        then pure s
        else defaultRunMessage msg s
    PassedSkillTest _ _ _ (TokenTarget token) _ _ -> do
      modifiers' <-
        map modifierType
          <$> getModifiersFor
                (toSource $ toAttrs s)
                (TokenFaceTarget $ tokenFace token)
                ()
      if IgnoreTokenEffects `elem` modifiers'
        then pure s
        else defaultRunMessage msg s
    _ -> defaultRunMessage msg s

instance
  ( HasCount DiscardCount env InvestigatorId
  , HasCount DoomCount env ()
  , HasCount DoomCount env EnemyId
  , HasCount EnemyCount env (InvestigatorLocation, [Trait])
  , HasCount EnemyCount env [Trait]
  , HasCount Shroud env LocationId
  , HasSet EnemyId env Trait
  , HasSet EnemyId env LocationId
  , HasSet LocationId env [Trait]
  , HasSet StoryEnemyId env CardCode
  , HasSet LocationId env ()
  , HasSet Trait env LocationId
  , HasList UnderneathCard env LocationId
  , HasTokenValue env InvestigatorId
  , HasId LocationId env InvestigatorId
  , HasId CardCode env EnemyId
  , HasStep env AgendaStep
  , HasModifiersFor env ()
  )
  => HasTokenValue env Scenario where
  getTokenValue s iid tokenFace = do
    modifiers' <-
      map modifierType
        <$> getModifiersFor
              (toSource $ toAttrs s)
              (TokenFaceTarget tokenFace)
              ()
    if IgnoreTokenEffects `elem` modifiers'
      then pure $ TokenValue tokenFace NoModifier
      else defaultGetTokenValue s iid tokenFace

instance Entity Scenario where
  type EntityId Scenario = ScenarioId
  type EntityAttrs Scenario = ScenarioAttrs

instance HasSet ScenarioLogKey env Scenario where
  getSet = pure . scenarioLog . toAttrs

instance HasCount ScenarioDeckCount env Scenario where
  getCount = getCount . toAttrs

instance HasCount SetAsideCount env (Scenario, CardCode) where
  getCount = getCount . first toAttrs

instance HasList SetAsideCard env Scenario where
  getList = getList . toAttrs

instance HasName env Scenario where
  getName = getName . toAttrs

newtype BaseScenario = BaseScenario ScenarioAttrs
  deriving stock Generic
  deriving anyclass HasRecord
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

instance HasTokenValue env InvestigatorId => HasTokenValue env BaseScenario where
  getTokenValue (BaseScenario attrs) iid = \case
    Skull -> pure $ TokenValue Skull (NegativeModifier 1)
    Cultist -> pure $ TokenValue Cultist (NegativeModifier 1)
    Tablet -> pure $ TokenValue Tablet (NegativeModifier 1)
    ElderThing -> pure $ TokenValue ElderThing (NegativeModifier 1)
    otherFace -> getTokenValue attrs iid otherFace

instance (HasId (Maybe LocationId) env LocationMatcher, ScenarioRunner env) => RunMessage env BaseScenario where
  runMessage msg a@(BaseScenario attrs) = case msg of
    ScenarioResolution NoResolution -> pure a
    _ -> BaseScenario <$> runMessage msg attrs

baseScenario
  :: CardCode
  -> Name
  -> [AgendaId]
  -> [ActId]
  -> Difficulty
  -> (ScenarioAttrs -> ScenarioAttrs)
  -> Scenario
baseScenario a b c d e f =
  BaseScenario' . BaseScenario . f $ baseAttrs a b c d e

lookupScenario :: ScenarioId -> Difficulty -> Scenario
lookupScenario = fromJustNote "Unknown scenario" . flip lookup allScenarios

difficultyOfScenario :: Scenario -> Difficulty
difficultyOfScenario = scenarioDifficulty . toAttrs

scenarioActs :: Scenario -> [ActId]
scenarioActs s = case scenarioActStack (toAttrs s) of
  [(_, actIds)] -> actIds
  _ -> error "Not able to handle multiple act stacks yet"

allScenarios :: HashMap ScenarioId (Difficulty -> Scenario)
allScenarios = mapFromList
  [ ("01104", TheGathering' . theGathering)
  , ("01120", TheMidnightMasks' . theMidnightMasks)
  , ("01142", TheDevourerBelow' . theDevourerBelow)
  , ("02041", ExtracurricularActivity' . extracurricularActivity)
  , ("02062", TheHouseAlwaysWins' . theHouseAlwaysWins)
  , ("02118", TheMiskatonicMuseum' . theMiskatonicMuseum)
  , ("02159", TheEssexCountyExpress' . theEssexCountyExpress)
  , ("02195", BloodOnTheAltar' . bloodOnTheAltar)
  , ("02236", UndimensionedAndUnseen' . undimensionedAndUnseen)
  , ("02274", WhereDoomAwaits' . whereDoomAwaits)
  , ("02311", LostInTimeAndSpace' . lostInTimeAndSpace)
  , ("50011", ReturnToTheGathering' . returnToTheGathering)
  , ("50025", ReturnToTheMidnightMasks' . returnToTheMidnightMasks)
  , ("50032", ReturnToTheDevourerBelow' . returnToTheDevourerBelow)
  , ("81001", CurseOfTheRougarou' . curseOfTheRougarou)
  , ("82001", CarnevaleOfHorrors' . carnevaleOfHorrors)
  ]

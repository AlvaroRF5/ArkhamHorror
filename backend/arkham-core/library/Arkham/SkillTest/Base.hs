{-# LANGUAGE TemplateHaskell #-}

module Arkham.SkillTest.Base where

import Arkham.Prelude

import Arkham.Action (Action)
import Arkham.Card
import Arkham.ChaosToken
import Arkham.Id
import Arkham.Json
import Arkham.SkillTest.Type
import Arkham.SkillTestResult
import Arkham.SkillType (SkillIcon (..), SkillType)
import Arkham.Source
import Arkham.Target
import Data.Aeson.TH

data SkillTestBaseValue
  = SkillBaseValue SkillType
  | AndSkillBaseValue [SkillType]
  | HalfResourcesOf InvestigatorId
  | StaticBaseValue Int
  deriving stock (Show, Eq, Ord)

data SkillTest = SkillTest
  { skillTestInvestigator :: InvestigatorId
  , skillTestResolveFailureInvestigator :: InvestigatorId
  , skillTestType :: SkillTestType
  , skillTestBaseValue :: SkillTestBaseValue
  , skillTestDifficulty :: Int
  , skillTestSetAsideChaosTokens :: [ChaosToken]
  , skillTestRevealedChaosTokens :: [ChaosToken] -- tokens may change from physical representation
  , skillTestResolvedChaosTokens :: [ChaosToken]
  , skillTestValueModifier :: Int
  , skillTestResult :: SkillTestResult
  , skillTestCommittedCards :: Map InvestigatorId [Card]
  , skillTestSource :: Source
  , skillTestTarget :: Target
  , skillTestAction :: Maybe Action
  , skillTestSubscribers :: [Target]
  , skillTestIsRevelation :: Bool
  , skillTestIconValues :: Map SkillIcon Int
  }
  deriving stock (Show, Eq, Ord)

allSkillTestChaosTokens :: SkillTest -> [ChaosToken]
allSkillTestChaosTokens SkillTest {..} =
  skillTestSetAsideChaosTokens <> skillTestRevealedChaosTokens <> skillTestResolvedChaosTokens

instance Targetable SkillTest where
  toTarget _ = SkillTestTarget
  isTarget _ SkillTestTarget = True
  isTarget _ _ = False

instance Sourceable SkillTest where
  toSource _ = SkillTestSource
  isSource _ SkillTestSource = True
  isSource _ _ = False

data SkillTestResultsData = SkillTestResultsData
  { skillTestResultsSkillValue :: Int
  , skillTestResultsIconValue :: Int
  , skillTestResultsChaosTokensValue :: Int
  , skillTestResultsDifficulty :: Int
  , skillTestResultsResultModifiers :: Maybe Int
  , skillTestResultsSuccess :: Bool
  }
  deriving stock (Eq, Show, Ord)

initSkillTest
  :: (Sourceable source, Targetable target)
  => InvestigatorId
  -> source
  -> target
  -> SkillType
  -> Int
  -> SkillTest
initSkillTest iid source target skillType =
  buildSkillTest
    iid
    source
    target
    (SkillSkillTest skillType)
    (SkillBaseValue skillType)

buildSkillTest
  :: (Sourceable source, Targetable target)
  => InvestigatorId
  -> source
  -> target
  -> SkillTestType
  -> SkillTestBaseValue
  -> Int
  -> SkillTest
buildSkillTest iid (toSource -> source) (toTarget -> target) stType bValue difficulty =
  SkillTest
    { skillTestInvestigator = iid
    , skillTestResolveFailureInvestigator = iid
    , skillTestType = stType
    , skillTestBaseValue = bValue
    , skillTestDifficulty = difficulty
    , skillTestSetAsideChaosTokens = mempty
    , skillTestRevealedChaosTokens = mempty
    , skillTestResolvedChaosTokens = mempty
    , skillTestValueModifier = 0
    , skillTestResult = Unrun
    , skillTestCommittedCards = mempty
    , skillTestSource = source
    , skillTestTarget = target
    , skillTestAction = Nothing
    , skillTestSubscribers = [toTarget iid]
    , skillTestIsRevelation = False
    , skillTestIconValues = iconValuesForSkillTestType stType
    }

iconValuesForSkillTestType :: SkillTestType -> Map SkillIcon Int
iconValuesForSkillTestType = \case
  SkillSkillTest skillType -> base <> singletonMap (SkillIcon skillType) 1
  AndSkillTest skillTypes -> base <> mapFromList (map ((,1) . SkillIcon) skillTypes)
  ResourceSkillTest -> base
 where
  base = mapFromList [(#wild, 1), (#wildMinus, -1)]

resetSkillTest :: SkillTest -> SkillTest
resetSkillTest skillTest =
  skillTest
    { skillTestSetAsideChaosTokens = mempty
    , skillTestRevealedChaosTokens = mempty
    , skillTestResolvedChaosTokens = mempty
    , skillTestValueModifier = 0
    , skillTestResult = Unrun
    , skillTestCommittedCards = mempty
    , skillTestSubscribers = [toTarget $ skillTestInvestigator skillTest]
    }

$(deriveJSON defaultOptions ''SkillTestBaseValue)
$(deriveJSON defaultOptions ''SkillTestResultsData)

instance FromJSON SkillTest where
  parseJSON = withObject "skillTest" $ \o -> do
    skillTestInvestigator <- o .: "investigator"
    skillTestResolveFailureInvestigator <- o .: "resolveFailureInvestigator"
    skillTestType <- o .: "type"
    skillTestBaseValue <- o .: "baseValue"
    skillTestDifficulty <- o .: "difficulty"
    skillTestSetAsideChaosTokens <- o .: "setAsideChaosTokens"
    skillTestRevealedChaosTokens <- o .: "revealedChaosTokens"
    skillTestResolvedChaosTokens <- o .: "resolvedChaosTokens"
    skillTestValueModifier <- o .: "valueModifier"
    skillTestResult <- o .: "result"
    skillTestCommittedCards <- o .: "committedCards"
    skillTestSource <- o .: "source"
    skillTestTarget <- o .: "target"
    skillTestAction <- o .: "action"
    skillTestSubscribers <- o .: "subscribers"
    skillTestIsRevelation <- o .: "isRevelation"
    skillTestIconValues <- o .:? "iconValues" .!= iconValuesForSkillTestType skillTestType
    pure SkillTest {..}

$(deriveToJSON (aesonOptions $ Just "skillTest") ''SkillTest)

module Arkham.Types.Act.Runner where

import Arkham.Import

import Arkham.Types.ScenarioLogKey
import Arkham.Types.Trait (Trait)

type ActRunner env
  = ( HasQueue env
    , HasCount ClueCount env AssetId
    , HasCount DamageCount env EnemyId
    , HasCount PlayerCount env ()
    , HasCount SpendableClueCount env InvestigatorId
    , HasCount SpendableClueCount env ()
    , HasId (Maybe LocationId) env LocationMatcher
    , HasId (Maybe OwnerId) env AssetId
    , HasId (Maybe StoryAssetId) env CardCode
    , HasId (Maybe StoryEnemyId) env CardCode
    , HasId CardCode env AssetId
    , HasId CardCode env EnemyId
    , HasId LeadInvestigatorId env ()
    , HasList Token env ()
    , HasList ResignedCardCode env ()
    , HasRecord env
    , HasSet AssetId env EnemyId
    , HasSet CompletedScenarioId env ()
    , HasSet EnemyId env LocationId
    , HasSet InvestigatorId env ()
    , HasSet InvestigatorId env (HashSet LocationId)
    , HasSet InvestigatorId env LocationId
    , HasSet InvestigatorId env LocationMatcher
    , HasSet InScenarioInvestigatorId env ()
    , HasSet LocationId env ()
    , HasSet LocationId env [Trait]
    , HasSet ScenarioLogKey env ()
    , HasSet Trait env AssetId
    , HasSet UnrevealedLocationId env ()
    , HasSet VictoryDisplayCardCode env ()
    , HasStep AgendaStep env
    , HasList LocationName env ()
    )

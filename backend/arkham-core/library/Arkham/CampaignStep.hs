module Arkham.CampaignStep where

import Arkham.Prelude

import Arkham.Id

data CampaignStep
  = PrologueStep
  | ScenarioStep ScenarioId
  | InterludeStep Int (Maybe InterludeKey)
  | UpgradeDeckStep CampaignStep
  | EpilogueStep
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

data InterludeKey = DanielSurvived | DanielWasPossessed | DanielDidNotSurvive
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

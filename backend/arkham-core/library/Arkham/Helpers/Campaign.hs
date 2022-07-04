module Arkham.Helpers.Campaign where

import Arkham.Prelude

import Arkham.Campaign.Attrs
import Arkham.Classes.Query
import {-# SOURCE #-} Arkham.GameEnv
import {-# SOURCE #-} Arkham.Game ()
import Arkham.Matcher
import Arkham.Projection
import Arkham.Id
import Arkham.CampaignStep

getCompletedScenarios :: (Monad m, HasGame m) => m (HashSet ScenarioId)
getCompletedScenarios = do
  mcampaignId <- selectOne TheCampaign
  case mcampaignId of
    Nothing -> pure mempty
    Just campaignId -> do
      completedSteps <- field CampaignCompletedSteps campaignId
      pure . setFromList $ flip mapMaybe completedSteps $ \case
        ScenarioStep scenarioId -> Just scenarioId
        _ -> Nothing

module Arkham.Types.Campaign.Campaigns.ReturnToNightOfTheZealot where

import Arkham.Prelude

import Arkham.Types.Campaign.Attrs
import Arkham.Types.Campaign.Campaigns.NightOfTheZealot
import Arkham.Types.Campaign.Runner
import Arkham.Types.CampaignId
import Arkham.Types.CampaignStep
import Arkham.Types.Classes
import Arkham.Types.Difficulty
import Arkham.Types.Message

newtype ReturnToNightOfTheZealot = ReturnToNightOfTheZealot NightOfTheZealot
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

returnToNightOfTheZealot :: Difficulty -> ReturnToNightOfTheZealot
returnToNightOfTheZealot difficulty =
  ReturnToNightOfTheZealot . NightOfTheZealot $ baseAttrs
    (CampaignId "50")
    "Return to the Night of the Zealot"
    difficulty
    (nightOfTheZealotChaosBagContents difficulty)

instance (CampaignRunner env) => RunMessage env ReturnToNightOfTheZealot where
  runMessage msg (ReturnToNightOfTheZealot nightOfTheZealot'@(NightOfTheZealot attrs@CampaignAttrs {..}))
    = case msg of
      NextCampaignStep _ -> do
        let
          nextStep = case campaignStep of
            Just PrologueStep -> Just (ScenarioStep "50011")
            Just (ScenarioStep "50011") -> Just (ScenarioStep "50025")
            Just (ScenarioStep "50025") -> Just (ScenarioStep "50032")
            _ -> Nothing
        unshiftMessage (CampaignStep nextStep)
        pure
          . ReturnToNightOfTheZealot
          . NightOfTheZealot
          $ attrs
          & (stepL .~ nextStep)
          & (completedStepsL %~ completeStep campaignStep)
      _ -> ReturnToNightOfTheZealot <$> runMessage msg nightOfTheZealot'

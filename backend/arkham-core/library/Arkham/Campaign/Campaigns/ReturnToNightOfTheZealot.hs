module Arkham.Campaign.Campaigns.ReturnToNightOfTheZealot where

import Arkham.Prelude

import Arkham.Campaigns.NightOfTheZealot.Import
import Arkham.Campaign.Campaigns.NightOfTheZealot
import Arkham.Campaign.Runner
import Arkham.CampaignId
import Arkham.Classes
import Arkham.Difficulty
import Arkham.Message

newtype ReturnToNightOfTheZealot = ReturnToNightOfTheZealot NightOfTheZealot
  deriving anyclass IsCampaign
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

returnToNightOfTheZealot :: Difficulty -> ReturnToNightOfTheZealot
returnToNightOfTheZealot difficulty =
  ReturnToNightOfTheZealot . NightOfTheZealot $ baseAttrs
    (CampaignId "50")
    "Return to the Night of the Zealot"
    difficulty
    (chaosBagContents difficulty)

instance RunMessage ReturnToNightOfTheZealot where
  runMessage msg (ReturnToNightOfTheZealot nightOfTheZealot'@(NightOfTheZealot attrs@CampaignAttrs {..}))
    = case msg of
      NextCampaignStep _ -> do
        let step = returnToNextStep attrs
        push (CampaignStep step)
        pure
          . ReturnToNightOfTheZealot
          . NightOfTheZealot
          $ attrs
          & (stepL .~ step)
          & (completedStepsL %~ completeStep campaignStep)
      _ -> ReturnToNightOfTheZealot <$> runMessage msg nightOfTheZealot'

module Arkham.Types.Campaign.Campaigns.NightOfTheZealot where

import Arkham.Prelude

import Arkham.Types.Campaign.Attrs
import Arkham.Types.Campaign.Runner
import Arkham.Types.CampaignId
import Arkham.Types.CampaignStep
import Arkham.Types.Classes
import Arkham.Types.Difficulty
import Arkham.Types.Message
import Arkham.Types.Token
import qualified Arkham.Types.Token as Token

newtype NightOfTheZealot = NightOfTheZealot CampaignAttrs
  deriving anyclass IsCampaign
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

nightOfTheZealot :: Difficulty -> NightOfTheZealot
nightOfTheZealot difficulty = NightOfTheZealot $ baseAttrs
  (CampaignId "01")
  "Night of the Zealot"
  difficulty
  (nightOfTheZealotChaosBagContents difficulty)

nightOfTheZealotChaosBagContents :: Difficulty -> [TokenFace]
nightOfTheZealotChaosBagContents = \case
  Easy ->
    [ Token.PlusOne
    , Token.PlusOne
    , Token.Zero
    , Token.Zero
    , Token.Zero
    , Token.MinusOne
    , Token.MinusOne
    , Token.MinusOne
    , Token.MinusTwo
    , Token.MinusTwo
    , Token.Skull
    , Token.Skull
    , Token.Cultist
    , Token.Tablet
    , Token.AutoFail
    , Token.ElderSign
    ]
  Standard ->
    [ Token.PlusOne
    , Token.Zero
    , Token.Zero
    , Token.MinusOne
    , Token.MinusOne
    , Token.MinusOne
    , Token.MinusTwo
    , Token.MinusTwo
    , Token.MinusThree
    , Token.MinusFour
    , Token.Skull
    , Token.Skull
    , Token.Cultist
    , Token.Tablet
    , Token.AutoFail
    , Token.ElderSign
    ]
  Hard ->
    [ Token.Zero
    , Token.Zero
    , Token.Zero
    , Token.MinusOne
    , Token.MinusOne
    , Token.MinusTwo
    , Token.MinusTwo
    , Token.MinusThree
    , Token.MinusThree
    , Token.MinusFour
    , Token.MinusFive
    , Token.Skull
    , Token.Skull
    , Token.Cultist
    , Token.Tablet
    , Token.AutoFail
    , Token.ElderSign
    ]
  Expert ->
    [ Token.Zero
    , Token.MinusOne
    , Token.MinusOne
    , Token.MinusTwo
    , Token.MinusTwo
    , Token.MinusThree
    , Token.MinusThree
    , Token.MinusFour
    , Token.MinusFour
    , Token.MinusFive
    , Token.MinusSix
    , Token.MinusEight
    , Token.Skull
    , Token.Skull
    , Token.Cultist
    , Token.Tablet
    , Token.AutoFail
    , Token.ElderSign
    ]

instance CampaignRunner env => RunMessage env NightOfTheZealot where
  runMessage msg c@(NightOfTheZealot attrs@CampaignAttrs {..}) = case msg of
    CampaignStep (Just PrologueStep) -> do
      investigatorIds <- getSetList ()
      c <$ pushAll
        [ AskMap
        . mapFromList
        $ [ ( iid
            , ChooseOne
              [ Run
                  [ Continue "Continue"
                  , FlavorText
                    (Just "The Ghouls Hunger...")
                    [ "Friday, September 18, 1925. Arkham, Massachusetts. It is\
                      \ the end of a long and abnormally hot summer. The first hints\
                      \ of autumn beckon, but a heavy heat persists, relentless. A\
                      \ silent, unspoken anger grips the town. Tempers are short, and\
                      \ in the last week alone there have been numerous reports of\
                      \ townspeople coming to heated, violent blows with one another\
                      \ over simple misunderstandings."
                    , "And now, a call from James Hankerson. He claims to have\
                      \ found a dismembered body in his barn."
                    , "Blaming the weather would be too easy. There is something\
                      \ wrong with this town, and not a whole lot this old soothsayer\
                      \ can do to stop the slide. My auguries indicate a small group of\
                      \ investigators will soon take note of these strange happenings\
                      \ and set forth to make things right. I’ll be watching their\
                      \ progress…but I won’t be holding my breath."
                    ]
                  ]
              ]
            )
          | iid <- investigatorIds
          ]
        , NextCampaignStep Nothing
        ]
    NextCampaignStep _ -> do
      let
        nextStep = case campaignStep of
          Just PrologueStep -> Just (ScenarioStep "01104")
          Just (ScenarioStep "01104") ->
            Just (UpgradeDeckStep $ ScenarioStep "01120")
          Just (ScenarioStep "01120") ->
            Just (UpgradeDeckStep $ ScenarioStep "01142")
          Just (UpgradeDeckStep nextStep') -> Just nextStep'
          _ -> Nothing
      push (CampaignStep nextStep)
      pure
        . NightOfTheZealot
        $ attrs
        & (stepL .~ nextStep)
        & (completedStepsL %~ completeStep campaignStep)
    _ -> NightOfTheZealot <$> runMessage msg attrs

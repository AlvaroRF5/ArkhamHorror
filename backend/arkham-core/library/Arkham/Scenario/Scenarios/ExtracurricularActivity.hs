module Arkham.Scenario.Scenarios.ExtracurricularActivity where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Asset.Cards qualified as Assets
import Arkham.CampaignLogKey
import Arkham.Card
import Arkham.Card.Cost
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Helpers.Campaign
import Arkham.Investigator.Types ( Field (..) )
import Arkham.Location.Cards qualified as Locations
import Arkham.Message
import Arkham.Projection
import Arkham.Resolution
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.Scenarios.ExtracurricularActivity.FlavorText
import Arkham.Source
import Arkham.Target
import Arkham.Token

newtype ExtracurricularActivity = ExtracurricularActivity ScenarioAttrs
  deriving stock Generic
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

extracurricularActivity :: Difficulty -> ExtracurricularActivity
extracurricularActivity difficulty = scenario
  ExtracurricularActivity
  "02041"
  "Extracurricular Activity"
  difficulty
  [ "orneLibrary        miskatonicQuad scienceBuilding alchemyLabs"
  , "humanitiesBuilding studentUnion   administrationBuilding ."
  , ".                  dormitories    facultyOffices         ."
  ]

instance HasTokenValue ExtracurricularActivity where
  getTokenValue iid tokenFace (ExtracurricularActivity attrs) =
    case tokenFace of
      Skull -> pure $ toTokenValue attrs Skull 1 2
      Cultist -> do
        discardCount <- fieldMap InvestigatorDiscard length iid
        pure $ TokenValue
          Cultist
          (NegativeModifier $ if discardCount >= 10
            then (if isEasyStandard attrs then 3 else 5)
            else 1
          )
      ElderThing -> pure $ TokenValue Tablet (NegativeModifier 0) -- determined by an effect
      otherFace -> getTokenValue iid otherFace attrs

instance RunMessage ExtracurricularActivity where
  runMessage msg s@(ExtracurricularActivity attrs) = case msg of
    Setup -> do
      investigatorIds <- allInvestigatorIds
      completedTheHouseAlwaysWins <- elem "02062" <$> getCompletedScenarios
      encounterDeck <- buildEncounterDeckExcluding
        [ toCardDef Enemies.theExperiment
        , toCardDef Assets.jazzMulligan
        , toCardDef Assets.alchemicalConcoction
        ]
        [ EncounterSet.ExtracurricularActivity
        , EncounterSet.Sorcery
        , EncounterSet.TheBeyond
        , EncounterSet.BishopsThralls
        , EncounterSet.Whippoorwills
        , EncounterSet.AncientEvils
        , EncounterSet.LockedDoors
        , EncounterSet.AgentsOfYogSothoth
        ]

      (miskatonicQuadId, placeMiskatonicQuad) <- placeLocationCard Locations.miskatonicQuad
      placeOtherLocations <- traverse placeLocationCard_ [Locations.humanitiesBuilding, Locations.orneLibrary, Locations.studentUnion, Locations.scienceBuilding, Locations.administrationBuilding]

      pushAll $
        [ SetEncounterDeck encounterDeck
        , SetAgendaDeck
        , SetActDeck
        , placeMiskatonicQuad
        ]
        <> placeOtherLocations
        <> [ RevealLocation Nothing miskatonicQuadId
           , MoveAllTo (toSource attrs) miskatonicQuadId
           , story investigatorIds intro
           ]

      setAsideCards <- traverse
        genCard
        [ toCardDef $ if completedTheHouseAlwaysWins
          then Locations.facultyOfficesTheHourIsLate
          else Locations.facultyOfficesTheNightIsStillYoung
        , toCardDef Assets.jazzMulligan
        , toCardDef Assets.alchemicalConcoction
        , toCardDef Enemies.theExperiment
        , toCardDef Locations.dormitories
        , toCardDef Locations.alchemyLabs
        , toCardDef Assets.professorWarrenRice
        ]

      ExtracurricularActivity <$> runMessage
        msg
        (attrs
        & (setAsideCardsL .~ setAsideCards)
        & (actStackL
          . at 1
          ?~ [Acts.afterHours, Acts.ricesWhereabouts, Acts.campusSafety]
          )
        & (agendaStackL
          . at 1
          ?~ [ Agendas.quietHalls
             , Agendas.deadOfNight
             , Agendas.theBeastUnleashed
             ]
          )
        )
    ResolveToken drawnToken ElderThing iid -> s <$ push
      (DiscardTopOfDeck
        iid
        (if isEasyStandard attrs then 2 else 3)
        (TokenEffectSource ElderThing)
        (Just $ TokenTarget drawnToken)
      )
    FailedSkillTest iid _ _ (TokenTarget token) _ _ ->
      s <$ case tokenFace token of
        Skull -> push $ DiscardTopOfDeck
          iid
          (if isEasyStandard attrs then 3 else 5)
          (TokenEffectSource Skull)
          Nothing
        _ -> pure ()
    DiscardedTopOfDeck _iid cards _ target@(TokenTarget token) ->
      s <$ case tokenFace token of
        ElderThing -> do
          let
            n = sum $ map
              (toPrintedCost . fromMaybe (StaticCost 0) . withCardDef cdCost)
              cards
          push $ CreateTokenValueEffect (-n) (toSource attrs) target
        _ -> pure ()
    ScenarioResolution NoResolution -> do
      iids <- allInvestigatorIds
      xp <- getXp
      pushAll
        $ [ story iids noResolution
          , Record ProfessorWarrenRiceWasKidnapped
          , Record TheInvestigatorsFailedToSaveTheStudents
          , AddToken Tablet
          ]
        <> [ GainXP iid (n + 1) | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    ScenarioResolution (Resolution 1) -> do
      leadInvestigatorId <- getLeadInvestigatorId
      iids <- allInvestigatorIds
      xp <- getXp
      pushAll
        $ [ story iids resolution1
          , Record TheInvestigatorsRescuedProfessorWarrenRice
          , AddToken Tablet
          , chooseOne
            leadInvestigatorId
            [ Label
              "Add Professor Warren Rice to your deck"
              [ AddCampaignCardToDeck
                  leadInvestigatorId
                  $ toCardDef Assets.professorWarrenRice
              ]
            , Label "Do not add Professor Warren Rice to your deck" []
            ]
          ]
        <> [ GainXP iid n | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    ScenarioResolution (Resolution 2) -> do
      iids <- allInvestigatorIds
      xp <- getXp
      pushAll
        $ [ story iids resolution2
          , Record ProfessorWarrenRiceWasKidnapped
          , Record TheStudentsWereRescued
          ]
        <> [ GainXP iid n | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    ScenarioResolution (Resolution 3) -> do
      iids <- allInvestigatorIds
      xp <- getXp
      pushAll
        $ [ story iids resolution3
          , Record ProfessorWarrenRiceWasKidnapped
          , Record TheExperimentWasDefeated
          ]
        <> [ GainXP iid n | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    ScenarioResolution (Resolution 4) -> do
      iids <- allInvestigatorIds
      xp <- getXp
      pushAll
        $ [ story iids resolution4
          , Record InvestigatorsWereUnconsciousForSeveralHours
          , Record ProfessorWarrenRiceWasKidnapped
          , Record TheInvestigatorsFailedToSaveTheStudents
          , AddToken Tablet
          ]
        <> [ GainXP iid (n + 1) | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    _ -> ExtracurricularActivity <$> runMessage msg attrs

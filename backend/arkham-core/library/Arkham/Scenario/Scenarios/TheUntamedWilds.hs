module Arkham.Scenario.Scenarios.TheUntamedWilds
  ( TheUntamedWilds(..)
  , theUntamedWilds
  ) where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Campaigns.TheForgottenAge.Helpers
import Arkham.Card
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Helpers.EncounterSet
import Arkham.Helpers.Query
import Arkham.Helpers.Scenario
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Message
import Arkham.Scenario.Runner
import Arkham.Scenarios.TheUntamedWilds.Story
import Arkham.Target
import Arkham.Token
import Arkham.Treachery.Cards qualified as Treacheries

newtype TheUntamedWilds = TheUntamedWilds ScenarioAttrs
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theUntamedWilds :: Difficulty -> TheUntamedWilds
theUntamedWilds difficulty = scenario
  TheUntamedWilds
  "04043"
  "The Untamed Wilds"
  difficulty
  [ ".               .            .             .            expeditionCamp .               .              ."
  , ".               pathOfThorns .             .            riverCanyon    .               .              ropeBridge"
  , ".               .            serpentsHaven .            .              circuitousTrail .              ."
  , "templeOfTheFang .            .             ruinsOfEztli .              .               overgrownRuins ."
  ]

instance HasTokenValue TheUntamedWilds where
  getTokenValue iid tokenFace (TheUntamedWilds attrs) = case tokenFace of
    Skull -> do
      vengeance <- getVengeanceInVictoryDisplay
      pure $ toTokenValue attrs Skull vengeance (vengeance + 1)
    Cultist -> do
      locationCount <- selectCount Anywhere
      pure $ toTokenValue attrs Cultist (min 5 locationCount) locationCount
    Tablet -> do
      explorationDeckCount <- length <$> getExplorationDeck
      pure $ toTokenValue
        attrs
        Tablet
        (min 5 explorationDeckCount)
        (max 3 explorationDeckCount)
    ElderThing -> do
      poisoned <-
        selectAny
        $ treacheryIs Treacheries.poisoned
        <> treacheryInThreatAreaOf iid
      if poisoned
        then pure $ TokenValue ElderThing AutoFailModifier
        else pure $ toTokenValue attrs ElderThing 2 3
    otherFace -> getTokenValue iid otherFace attrs

instance RunMessage TheUntamedWilds where
  runMessage msg s@(TheUntamedWilds attrs) = case msg of
    Setup -> do
      investigatorIds <- getInvestigatorIds
      expeditionCamp <- genCard Locations.expeditionCamp

      explorationDeck <- shuffleM =<< traverse
        genCard
        [ Locations.pathOfThorns
        , Locations.riverCanyon
        , Locations.ropeBridge
        , Locations.serpentsHaven
        , Locations.circuitousTrail
        , Treacheries.lostInTheWilds
        , Treacheries.overgrowth
        , Treacheries.snakeBite
        , Treacheries.lowOnSupplies
        , Treacheries.arrowsFromTheTrees
        ]
      agentsOfYig <- map EncounterCard
        <$> gatherEncounterSet EncounterSet.AgentsOfYig
      setAsideCards <- (agentsOfYig <>) <$> traverse
        genCard
        [ Locations.ruinsOfEztli
        , Locations.templeOfTheFang
        , Locations.overgrownRuins
        , Treacheries.poisoned
        , Treacheries.poisoned
        , Treacheries.poisoned
        , Treacheries.poisoned
        ]
      pushAll
        $ [ story investigatorIds intro
          , SetAgendaDeck
          , SetActDeck
          , PlaceLocation expeditionCamp
          , MoveAllTo (toSource attrs) (toLocationId expeditionCamp)
          ]
      TheUntamedWilds <$> runMessage
        msg
        (attrs
        & (decksL . at ExplorationDeck ?~ explorationDeck)
        & (setAsideCardsL .~ setAsideCards)
        & (actStackL
          . at 1
          ?~ [ Acts.exploringTheRainforest
             , Acts.huntressOfTheEztli
             , Acts.searchForTheRuins
             , Acts.theGuardedRuins
             ]
          )
        & (agendaStackL
          . at 1
          ?~ [Agendas.expeditionIntoTheWild, Agendas.intruders]
          )
        )
    FailedSkillTest iid _ _ (TokenTarget token) _ _ -> case tokenFace token of
      ElderThing -> do
        isPoisoned <-
          selectAny
          $ treacheryIs Treacheries.poisoned
          <> treacheryInThreatAreaOf iid
        unless isPoisoned $ do
          let
            poisoned = fromJustNote "not enough poison cards" $ find
              ((== Treacheries.poisoned) . toCardDef)
              (scenarioSetAsideCards attrs)
          push $ CreateWeaknessInThreatArea poisoned iid
        pure s
      _ -> pure s
    _ -> TheUntamedWilds <$> runMessage msg attrs

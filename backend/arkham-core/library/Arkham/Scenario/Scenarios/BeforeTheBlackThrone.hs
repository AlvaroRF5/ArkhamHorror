module Arkham.Scenario.Scenarios.BeforeTheBlackThrone (
  BeforeTheBlackThrone (..),
  beforeTheBlackThrone,
) where

import Arkham.Prelude hiding ((<|))

import Arkham.Act.Cards qualified as Acts
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Card
import Arkham.ChaosToken
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Helpers
import Arkham.Helpers.Query
import Arkham.Helpers.Scenario
import Arkham.Id
import Arkham.Investigator.Types (Field (..))
import Arkham.Location.Cards qualified as Locations
import Arkham.Message
import Arkham.Placement
import Arkham.Projection
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.Scenarios.BeforeTheBlackThrone.Cosmos
import Arkham.Scenarios.BeforeTheBlackThrone.Story

newtype BeforeTheBlackThrone = BeforeTheBlackThrone (ScenarioAttrs `With` Cosmos Card LocationId)
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

beforeTheBlackThrone :: Difficulty -> BeforeTheBlackThrone
beforeTheBlackThrone difficulty =
  scenario
    (BeforeTheBlackThrone . (`with` initCosmos))
    "05325"
    "Before the Black Throne"
    difficulty
    []

instance HasChaosTokenValue BeforeTheBlackThrone where
  getChaosTokenValue iid tokenFace (BeforeTheBlackThrone (attrs `With` _)) = case tokenFace of
    Skull -> pure $ toChaosTokenValue attrs Skull 3 5
    Cultist -> pure $ ChaosTokenValue Cultist NoModifier
    Tablet -> pure $ ChaosTokenValue Tablet NoModifier
    ElderThing -> pure $ ChaosTokenValue ElderThing NoModifier
    otherFace -> getChaosTokenValue iid otherFace attrs

-- Æ Find the Hideous Palace, Court of the Great Old Ones, and The Black Throne locations. (They are on the revealed side of 3 of the “Cosmos” locations.) Set those locations aside, out of play.
-- Æ Shuffle the remaining location cards into a separate deck, Cosmos‐side faceup. This deck is called the Cosmos (see “The Cosmos,” below).
-- Æ Take the set‐aside Hideous Palace and the top card of the Cosmos, and shuffle them so you cannot tell which is which. Then, put them into play along with facedown player cards from the top of the lead investigator’s deck, as depicted in “Location Placement for Setup / Act 1.” Facedown player cards represent empty space (see “Empty Space” on the next page).
-- Æ Set the Piper of Azathoth enemy aside, out of play.
-- Æ Put Azathoth into play next to the agenda deck. For the remainder of the scenario, Azathoth is in play, but is not at any location.
-- Æ Check Campaign Log. For each tally mark recorded next to the path winds before you, place 1 resource on the scenario reference card.
-- Æ Shuffle the remainder of the encounter cards to build the encounter deck.
--
--
instance RunMessage BeforeTheBlackThrone where
  runMessage msg s@(BeforeTheBlackThrone (attrs `With` cosmos)) = case msg of
    PreScenarioSetup -> do
      investigators <- allInvestigators
      pushAll [story investigators intro]
      pure s
    Setup -> do
      encounterDeck <-
        buildEncounterDeckExcluding
          [Enemies.piperOfAzathoth, Enemies.azathoth]
          [ EncounterSet.BeforeTheBlackThrone
          , EncounterSet.AgentsOfAzathoth
          , EncounterSet.InexorableFate
          , EncounterSet.AncientEvils
          , EncounterSet.DarkCult
          ]
      (cosmicIngress, placeCosmicIngress) <- placeLocationCard Locations.cosmicIngress

      cosmosCards' <-
        shuffleM
          =<< genCards
            [ Locations.infinityOfDarkness
            , Locations.infinityOfDarkness
            , Locations.infinityOfDarkness
            , Locations.cosmicGate
            , Locations.pathwayIntoVoid
            , Locations.pathwayIntoVoid
            , Locations.dancersMist
            , Locations.dancersMist
            , Locations.dancersMist
            , Locations.flightIntoOblivion
            ]

      let
        (topCosmosCard, cosmosCards) =
          case cosmosCards' of
            (x : xs) -> (x, xs)
            _ -> error "did not have enough cards"

      hideousPalace <- genCard Locations.hideousPalace

      (firstCosmosCard, secondCosmosCard) <-
        shuffleM [topCosmosCard, hideousPalace] <&> \case
          [x, y] -> (x, y)
          _ -> error "did not have enough cards"

      lead <- getLead
      (map toCard -> cards, _) <- fieldMap InvestigatorDeck (draw 6) lead

      (firstCosmos, placeFirstCosmos) <- placeLocation firstCosmosCard
      (secondCosmos, placeSecondCosmos) <- placeLocation secondCosmosCard

      let
        emptySpaceLocations =
          [ Pos 0 1
          , Pos 0 (-1)
          , Pos 1 1
          , Pos 1 0
          , Pos 1 (-1)
          , Pos 2 0
          ]
        emptySpaces = zip emptySpaceLocations cards

      let
        cosmos' =
          foldr
            (insertCosmos . uncurry EmptySpace)
            ( insertCosmos (CosmosLocation (Pos 2 1) firstCosmos)
                $ insertCosmos (CosmosLocation (Pos 2 (-1)) secondCosmos)
                $ insertCosmos (CosmosLocation (Pos 0 0) cosmicIngress) cosmos
            )
            emptySpaces

      placeEmptySpaces <- concatForM emptySpaces $ \(pos, _) -> do
        (emptySpace', placeEmptySpace) <- placeLocationCard Locations.emptySpace
        pure [placeEmptySpace, SetLocationLabel emptySpace' (tshow pos)]

      azathoth <- genCard Enemies.azathoth
      createAzathoth <- toMessage <$> createEnemy azathoth Global

      pushAll
        $ [ SetEncounterDeck encounterDeck
          , SetActDeck
          , SetAgendaDeck
          , placeCosmicIngress
          , SetLocationLabel cosmicIngress (tshow (Pos 0 0))
          , placeFirstCosmos
          , SetLocationLabel firstCosmos (tshow (Pos 2 1))
          , placeSecondCosmos
          , SetLocationLabel secondCosmos (tshow (Pos 2 (-1)))
          , MoveAllTo (toSource attrs) cosmicIngress
          , createAzathoth
          ]
          <> map (ObtainCard . toCard) cards
          <> placeEmptySpaces

      agendas <- genCards [Agendas.wheelOfFortuneX, Agendas.itAwaits, Agendas.theFinalCountdown]

      acts <- genCards [Acts.theCosmosBeckons, Acts.inAzathothsDomain, Acts.whatMustBeDone]

      BeforeTheBlackThrone
        . (`with` cosmos')
          <$> runMessage
            msg
            ( attrs
                & (decksL . at CosmosDeck ?~ cosmosCards)
                & locationLayoutL .~ cosmosToGrid cosmos'
                & (actStackL . at 1 ?~ acts)
                & (agendaStackL . at 1 ?~ agendas)
            )
    _ -> BeforeTheBlackThrone . (`with` cosmos) <$> runMessage msg attrs

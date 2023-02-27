module Arkham.Act.Cards.FindingLadyEsprit
  ( FindingLadyEsprit(..)
  , findingLadyEsprit
  ) where

import Arkham.Prelude

import Arkham.Act.Types
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Helpers
import Arkham.Act.Runner
import Arkham.Asset.Cards qualified as Assets
import Arkham.Card
import Arkham.Classes
import Arkham.Deck qualified as Deck
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import Arkham.Placement
import Arkham.Scenarios.CurseOfTheRougarou.Helpers
import Arkham.Trait
import Arkham.Treachery.Cards qualified as Treacheries
import Data.HashSet qualified as HashSet
import Data.Maybe (fromJust)

newtype FindingLadyEsprit = FindingLadyEsprit ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

findingLadyEsprit :: ActCard FindingLadyEsprit
findingLadyEsprit = act
  (1, A)
  FindingLadyEsprit
  Cards.findingLadyEsprit
  (Just $ GroupClueCost (PerPlayer 1) (LocationWithTrait Bayou))

instance RunMessage FindingLadyEsprit where
  runMessage msg a@(FindingLadyEsprit attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ _ | aid == actId && onSide B attrs -> do
      ladyEspritSpawnLocation <-
        fromJust . headMay . setToList <$> bayouLocations
      ladyEsprit <- genCard Assets.ladyEsprit
      setAsideLocations <- selectList $ SetAsideCardMatch LocationCard

      let
        traits =
          toList
            $ HashSet.unions (map toTraits setAsideLocations)
            `intersect` setFromList
                          [NewOrleans, Riverside, Wilderness, Unhallowed]
        locationsFor t = filter (member t . toTraits) setAsideLocations

      setAsideLocationsWithLabels <- concatMapM (\t -> locationsWithLabels t (locationsFor t)) traits
      placements <- for setAsideLocationsWithLabels $ \(label, card) -> do
        (locationId, locationPlacement) <- placeLocation card
        pure [locationPlacement, SetLocationLabel locationId label]

      pushAll $ [CreateAssetAt ladyEsprit (AtLocation ladyEspritSpawnLocation)]
        <> concat placements
        <> [NextAdvanceActStep aid 2]
      pure a
    NextAdvanceActStep aid 2 | aid == actId && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      curseOfTheRougarouSet <- map EncounterCard <$> gatherEncounterSet
        EncounterSet.CurseOfTheRougarou
      rougarouSpawnLocations <- setToList <$> nonBayouLocations
      theRougarou <- genCard Enemies.theRougarou
      curseOfTheRougarou <- genCard Treacheries.curseOfTheRougarou
      pushAll $
         [ chooseOne
             leadInvestigatorId
             [ targetLabel lid [CreateEnemyAt theRougarou lid Nothing]
             | lid <- rougarouSpawnLocations
             ]
         ]
        <> [ ShuffleEncounterDiscardBackIn
           , ShuffleCardsIntoDeck Deck.EncounterDeck curseOfTheRougarouSet
           , AddCampaignCardToDeck
             leadInvestigatorId
             $ toCardDef Treacheries.curseOfTheRougarou
           , CreateWeaknessInThreatArea curseOfTheRougarou leadInvestigatorId
           , AdvanceActDeck actDeckId (toSource attrs)
           ]
      pure a
    _ -> FindingLadyEsprit <$> runMessage msg attrs

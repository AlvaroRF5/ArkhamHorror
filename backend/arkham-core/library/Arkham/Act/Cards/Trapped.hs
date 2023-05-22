module Arkham.Act.Cards.Trapped where

import Arkham.Prelude

import Arkham.Act.Types
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Classes
import Arkham.Helpers.Query
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher (LocationMatcher(..))
import Arkham.Message

newtype Trapped = Trapped ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

trapped :: ActCard Trapped
trapped =
  act (1, A) Trapped Cards.trapped (Just $ GroupClueCost (PerPlayer 2) Anywhere)

instance RunMessage Trapped where
  runMessage msg a@(Trapped attrs) = case msg of
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs -> do
      studyId <- selectJust $ LocationWithTitle "Study"
      enemyIds <- enemiesAt studyId

      (hallwayId, placeHallway) <- placeSetAsideLocation Locations.hallway
      placeCellar <- placeSetAsideLocation_ Locations.cellar
      placeAttic <- placeSetAsideLocation_ Locations.attic
      placeParlor <- placeSetAsideLocation_ Locations.parlor

      pushAll $
        [ placeHallway
        , placeCellar
        , placeAttic
        , placeParlor
        ]
       <> map (toDiscard attrs) enemyIds
       <> [ RevealLocation Nothing hallwayId
          , MoveAllTo (toSource attrs) hallwayId
          , RemoveLocation studyId
          , advanceActDeck attrs
          ]
      pure a
    _ -> Trapped <$> runMessage msg attrs

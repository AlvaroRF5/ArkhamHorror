module Arkham.Location.Cards.ChapelOfStAubertWatersForbidden
  ( chapelOfStAubertWatersForbidden
  , ChapelOfStAubertWatersForbidden(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.GameValue
import Arkham.Helpers.Log
import Arkham.Helpers.Modifiers
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.ScenarioLogKey

newtype ChapelOfStAubertWatersForbidden = ChapelOfStAubertWatersForbidden LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

chapelOfStAubertWatersForbidden :: LocationCard ChapelOfStAubertWatersForbidden
chapelOfStAubertWatersForbidden = location
  ChapelOfStAubertWatersForbidden
  Cards.chapelOfStAubertWatersForbidden
  2
  (PerPlayer 3)
  Moon
  [Square]

instance HasModifiersFor ChapelOfStAubertWatersForbidden where
  getModifiersFor _ target (ChapelOfStAubertWatersForbidden attrs)
    | isTarget attrs target = do
      foundAGuide <- remembered FoundAGuide
      pure $ toModifiers
        attrs
        [ Blocked | not (locationRevealed attrs) && not foundAGuide ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities ChapelOfStAubertWatersForbidden where
  getAbilities (ChapelOfStAubertWatersForbidden attrs) = getAbilities attrs
    -- withBaseAbilities attrs []

instance RunMessage ChapelOfStAubertWatersForbidden where
  runMessage msg (ChapelOfStAubertWatersForbidden attrs) =
    ChapelOfStAubertWatersForbidden <$> runMessage msg attrs

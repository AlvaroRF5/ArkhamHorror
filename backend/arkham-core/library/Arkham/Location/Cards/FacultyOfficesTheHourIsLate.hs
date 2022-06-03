module Arkham.Location.Cards.FacultyOfficesTheHourIsLate where

import Arkham.Prelude

import Arkham.Location.Cards qualified as Cards (facultyOfficesTheHourIsLate)
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Modifier

newtype FacultyOfficesTheHourIsLate = FacultyOfficesTheHourIsLate LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

facultyOfficesTheHourIsLate :: LocationCard FacultyOfficesTheHourIsLate
facultyOfficesTheHourIsLate = location
  FacultyOfficesTheHourIsLate
  Cards.facultyOfficesTheHourIsLate
  2
  (Static 0)
  T
  [Circle]

instance HasModifiersFor env FacultyOfficesTheHourIsLate where
  getModifiersFor _ target (FacultyOfficesTheHourIsLate attrs)
    | isTarget attrs target = pure
    $ toModifiers attrs [ Blocked | not (locationRevealed attrs) ]
  getModifiersFor _ _ _ = pure []

instance LocationRunner env => RunMessage FacultyOfficesTheHourIsLate where
  runMessage msg (FacultyOfficesTheHourIsLate attrs) =
    FacultyOfficesTheHourIsLate <$> runMessage msg attrs

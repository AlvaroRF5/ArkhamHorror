module Arkham.Types.Location.Cards.AsylumHallsWesternPatientWing_169
  ( asylumHallsWesternPatientWing_169
  , AsylumHallsWesternPatientWing_169(..)
  ) where

import Arkham.Prelude

import Arkham.Location.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs

newtype AsylumHallsWesternPatientWing_169 = AsylumHallsWesternPatientWing_169 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

asylumHallsWesternPatientWing_169
  :: LocationCard AsylumHallsWesternPatientWing_169
asylumHallsWesternPatientWing_169 = location
  AsylumHallsWesternPatientWing_169
  Cards.asylumHallsWesternPatientWing_169
  3
  (PerPlayer 1)
  Circle
  [Hourglass, Triangle, Diamond]

instance HasAbilities AsylumHallsWesternPatientWing_169 where
  getAbilities (AsylumHallsWesternPatientWing_169 attrs) = getAbilities attrs

instance LocationRunner env => RunMessage env AsylumHallsWesternPatientWing_169 where
  runMessage msg (AsylumHallsWesternPatientWing_169 attrs) =
    AsylumHallsWesternPatientWing_169 <$> runMessage msg attrs

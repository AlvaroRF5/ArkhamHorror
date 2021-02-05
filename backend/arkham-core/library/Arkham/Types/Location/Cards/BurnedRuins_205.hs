module Arkham.Types.Location.Cards.BurnedRuins_205
  ( burnedRuins_205
  , BurnedRuins_205(..)
  ) where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype BurnedRuins_205 = BurnedRuins_205 LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

burnedRuins_205 :: BurnedRuins_205
burnedRuins_205 = BurnedRuins_205 $ baseAttrs
  "02205"
  (Name "Burned Ruins" Nothing)
  EncounterSet.BloodOnTheAltar
  2
  (Static 3)
  Triangle
  [Square, Diamond]
  [Dunwich]

instance HasModifiersFor env BurnedRuins_205 where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env BurnedRuins_205 where
  getActions iid window (BurnedRuins_205 attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env BurnedRuins_205 where
  runMessage msg (BurnedRuins_205 attrs) =
    BurnedRuins_205 <$> runMessage msg attrs

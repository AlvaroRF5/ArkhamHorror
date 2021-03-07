module Arkham.Types.Location.Cards.Study where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Name

newtype Study = Study LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

study :: LocationId -> Study
study lid = Study $ baseAttrs
  lid
  "01111"
  (Name "Study" Nothing)
  EncounterSet.TheGathering
  2
  (PerPlayer 2)
  Circle
  mempty
  mempty

instance HasModifiersFor env Study where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Study where
  getActions i window (Study attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env Study where
  runMessage msg (Study attrs) = Study <$> runMessage msg attrs

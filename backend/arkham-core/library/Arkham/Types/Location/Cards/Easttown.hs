module Arkham.Types.Location.Cards.Easttown where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Modifier
import Arkham.Types.Name
import Arkham.Types.Target
import Arkham.Types.Trait

newtype Easttown = Easttown LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

easttown :: LocationId -> Easttown
easttown lid = Easttown $ baseAttrs
  lid
  "01132"
  (Name "Easttown" Nothing)
  EncounterSet.TheMidnightMasks
  2
  (PerPlayer 1)
  Moon
  [Circle, Triangle]
  [Arkham]

instance HasModifiersFor env Easttown where
  getModifiersFor _ (InvestigatorTarget iid) (Easttown attrs) =
    pure $ toModifiers
      attrs
      [ ReduceCostOf [Ally] 2 | iid `member` locationInvestigators attrs ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env Easttown where
  getActions i window (Easttown attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env Easttown where
  runMessage msg (Easttown attrs) = Easttown <$> runMessage msg attrs

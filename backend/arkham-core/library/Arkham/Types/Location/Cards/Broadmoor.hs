module Arkham.Types.Location.Cards.Broadmoor
  ( Broadmoor(..)
  , broadmoor
  ) where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Name
import Arkham.Types.Trait

newtype Broadmoor = Broadmoor LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

broadmoor :: LocationId -> Broadmoor
broadmoor lid = Broadmoor $ base { locationVictory = Just 1 }
 where
  base = baseAttrs
    lid
    "81009"
    (Name "Broadmoor" Nothing)
    EncounterSet.CurseOfTheRougarou
    3
    (PerPlayer 1)
    Plus
    [Square, Plus]
    [NewOrleans]

instance HasModifiersFor env Broadmoor where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Broadmoor where
  getActions = withResignAction

instance LocationRunner env => RunMessage env Broadmoor where
  runMessage msg (Broadmoor attrs) = Broadmoor <$> runMessage msg attrs

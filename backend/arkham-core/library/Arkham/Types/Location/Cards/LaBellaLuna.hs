module Arkham.Types.Location.Cards.LaBellaLuna
  ( laBellaLuna
  , LaBellaLuna(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (laBellaLuna)
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol

newtype LaBellaLuna = LaBellaLuna LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

laBellaLuna :: LocationCard LaBellaLuna
laBellaLuna =
  location LaBellaLuna Cards.laBellaLuna 2 (PerPlayer 1) Moon [Circle]

instance HasModifiersFor env LaBellaLuna

instance ActionRunner env => HasActions env LaBellaLuna where
  getActions = withResignAction

instance LocationRunner env => RunMessage env LaBellaLuna where
  runMessage msg (LaBellaLuna attrs) = LaBellaLuna <$> runMessage msg attrs

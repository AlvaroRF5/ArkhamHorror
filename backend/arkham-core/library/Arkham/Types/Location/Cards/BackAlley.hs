module Arkham.Types.Location.Cards.BackAlley
  ( backAlley
  , BackAlley(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (backAlley)
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol

newtype BackAlley = BackAlley LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

backAlley :: LocationCard BackAlley
backAlley = locationWith
  BackAlley
  Cards.backAlley
  1
  (PerPlayer 1)
  T
  [Diamond]
  (revealedSymbolL .~ Squiggle)

instance HasModifiersFor env BackAlley where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env BackAlley where
  getActions = withResignAction

instance LocationRunner env => RunMessage env BackAlley where
  runMessage msg (BackAlley attrs) = BackAlley <$> runMessage msg attrs

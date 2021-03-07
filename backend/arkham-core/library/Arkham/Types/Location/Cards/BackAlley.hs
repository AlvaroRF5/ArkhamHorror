module Arkham.Types.Location.Cards.BackAlley
  ( backAlley
  , BackAlley(..)
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
import Arkham.Types.Trait hiding (Cultist)

newtype BackAlley = BackAlley LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

backAlley :: LocationId -> BackAlley
backAlley lid = BackAlley
  $ base { locationVictory = Just 1, locationRevealedSymbol = Squiggle }
 where
  base = baseAttrs
    lid
    "02077"
    (Name "Back Alley" Nothing)
    EncounterSet.TheHouseAlwaysWins
    1
    (PerPlayer 1)
    T
    [Diamond]
    [CloverClub]

instance HasModifiersFor env BackAlley where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env BackAlley where
  getActions = withResignAction

instance LocationRunner env => RunMessage env BackAlley where
  runMessage msg (BackAlley attrs) = BackAlley <$> runMessage msg attrs

module Arkham.Types.Location.Cards.DarkenedHall
  ( darkenedHall
  , DarkenedHall(..)
  )
where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Trait hiding (Cultist)

newtype DarkenedHall = DarkenedHall LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

darkenedHall :: LocationId -> DarkenedHall
darkenedHall =
  DarkenedHall
    . (revealedConnectedSymbolsL
      .~ setFromList [Triangle, T, Hourglass, Plus, Squiggle]
      )
    . baseAttrs
        "02074"
        "Darkened Hall"
        EncounterSet.TheHouseAlwaysWins
        4
        (Static 0)
        Diamond
        [Triangle]
        [CloverClub]

instance HasModifiersFor env DarkenedHall where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env DarkenedHall where
  getActions iid window (DarkenedHall attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env DarkenedHall where
  runMessage msg (DarkenedHall attrs@LocationAttrs {..}) = case msg of
    RevealLocation _ lid | lid == locationId -> do
      locations <- shuffleM ["02075", "02076", "02077"]
      randomIds <- replicateM 3 getRandom
      unshiftMessages $ concat
        [ [ PlaceLocation location locationId'
          , SetLocationLabel locationId' label'
          ]
        | (locationId', (label', location)) <- zip randomIds $ zip
          ["backHallDoorway1", "backHallDoorway2", "backHallDoorway3"]
          locations
        ]
      DarkenedHall <$> runMessage msg attrs
    _ -> DarkenedHall <$> runMessage msg attrs

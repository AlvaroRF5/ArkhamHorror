module Arkham.Types.Location.Cards.MuseumEntrance
  ( museumEntrance
  , MuseumEntrance(..)
  )
where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype MuseumEntrance = MuseumEntrance LocationAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

museumEntrance :: MuseumEntrance
museumEntrance = MuseumEntrance $ baseAttrs
  "02126"
  (Name "Museum Entrance" Nothing)
  EncounterSet.TheMiskatonicMuseum
  3
  (Static 2)
  Circle
  [Square]
  (singleton Miskatonic)

instance HasModifiersFor env MuseumEntrance where
  getModifiersFor _ (InvestigatorTarget iid) (MuseumEntrance location) =
    pure $ toModifiers location [ CannotGainResources | iid `on` location ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env MuseumEntrance where
  getActions iid NonFast (MuseumEntrance location) | locationRevealed location =
    withBaseActions iid NonFast location
      $ pure [ resignAction iid location | iid `on` location ]
  getActions i window (MuseumEntrance location) = getActions i window location

instance LocationRunner env => RunMessage env MuseumEntrance where
  runMessage msg (MuseumEntrance location) =
    MuseumEntrance <$> runMessage msg location

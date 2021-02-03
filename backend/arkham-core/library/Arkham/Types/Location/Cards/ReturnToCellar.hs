module Arkham.Types.Location.Cards.ReturnToCellar where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner

newtype ReturnToCellar = ReturnToCellar LocationAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

returnToCellar :: ReturnToCellar
returnToCellar = ReturnToCellar $ baseAttrs
  "50020"
  (Name "Cellar" Nothing)
  EncounterSet.ReturnToTheGathering
  2
  (PerPlayer 1)
  Plus
  [Square, Squiggle]
  mempty

instance HasModifiersFor env ReturnToCellar where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ReturnToCellar where
  getActions i window (ReturnToCellar attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env ReturnToCellar where
  runMessage msg (ReturnToCellar attrs) = case msg of
    RevealLocation _ lid | lid == locationId attrs -> do
      unshiftMessage (PlaceLocation "50021")
      ReturnToCellar <$> runMessage msg attrs
    _ -> ReturnToCellar <$> runMessage msg attrs

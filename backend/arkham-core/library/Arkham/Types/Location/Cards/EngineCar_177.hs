module Arkham.Types.Location.Cards.EngineCar_177
  ( engineCar_177
  , EngineCar_177(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (engineCar_177)
import Arkham.Types.Classes
import Arkham.Types.Direction
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Query

newtype EngineCar_177 = EngineCar_177 LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

engineCar_177 :: LocationCard EngineCar_177
engineCar_177 = locationWith
  EngineCar_177
  Cards.engineCar_177
  1
  (PerPlayer 2)
  NoSymbol
  []
  (connectsToL .~ singleton LeftOf)

instance HasCount ClueCount env LocationId => HasModifiersFor env EngineCar_177 where
  getModifiersFor _ target (EngineCar_177 l@LocationAttrs {..})
    | isTarget l target = case lookup LeftOf locationDirections of
      Just leftLocation -> do
        clueCount <- unClueCount <$> getCount leftLocation
        pure $ toModifiers l [ Blocked | not locationRevealed && clueCount > 0 ]
      Nothing -> pure []
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env EngineCar_177 where
  getActions iid window (EngineCar_177 attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env EngineCar_177 where
  runMessage msg (EngineCar_177 attrs) = case msg of
    RevealLocation (Just iid) lid | lid == locationId attrs -> do
      pushAll (replicate 3 $ InvestigatorDrawEncounterCard iid)
      EngineCar_177 <$> runMessage msg attrs
    _ -> EngineCar_177 <$> runMessage msg attrs

module Arkham.Types.Location.Cards.EngineCar_177
  ( engineCar_177
  , EngineCar_177(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (engineCar_177)
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Criteria
import Arkham.Types.Direction
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Matcher
import Arkham.Types.Message hiding (RevealLocation)
import Arkham.Types.Modifier
import Arkham.Types.Query
import qualified Arkham.Types.Timing as Timing

newtype EngineCar_177 = EngineCar_177 LocationAttrs
  deriving anyclass IsLocation
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

instance HasAbilities env EngineCar_177 where
  getAbilities i window (EngineCar_177 x) = withBaseAbilities i window x $ pure
    [ restrictedAbility x 1 Here
      $ ForcedAbility
      $ RevealLocation Timing.After You
      $ LocationWithId
      $ toId x
    | locationRevealed x
    ]

instance LocationRunner env => RunMessage env EngineCar_177 where
  runMessage msg l@(EngineCar_177 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      l <$ pushAll (replicate 3 $ InvestigatorDrawEncounterCard iid)
    _ -> EngineCar_177 <$> runMessage msg attrs

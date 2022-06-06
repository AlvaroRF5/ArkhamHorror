module Arkham.Location.Cards.EngineCar_177
  ( engineCar_177
  , EngineCar_177(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (engineCar_177)
import Arkham.Classes
import Arkham.Criteria
import Arkham.Direction
import Arkham.GameValue
import Arkham.Id
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message hiding (RevealLocation)
import Arkham.Modifier
import Arkham.Query
import Arkham.Timing qualified as Timing

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

instance HasCount ClueCount env LocationId => HasModifiersFor EngineCar_177 where
  getModifiersFor _ target (EngineCar_177 l@LocationAttrs {..})
    | isTarget l target = case lookup LeftOf locationDirections of
      Just leftLocation -> do
        clueCount <- unClueCount <$> getCount leftLocation
        pure $ toModifiers l [ Blocked | not locationRevealed && clueCount > 0 ]
      Nothing -> pure []
  getModifiersFor _ _ _ = pure []

instance HasAbilities EngineCar_177 where
  getAbilities (EngineCar_177 x) = withBaseAbilities x $
    [ restrictedAbility x 1 Here
      $ ForcedAbility
      $ RevealLocation Timing.After You
      $ LocationWithId
      $ toId x
    | locationRevealed x
    ]

instance RunMessage EngineCar_177 where
  runMessage msg l@(EngineCar_177 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      l <$ pushAll (replicate 3 $ InvestigatorDrawEncounterCard iid)
    _ -> EngineCar_177 <$> runMessage msg attrs

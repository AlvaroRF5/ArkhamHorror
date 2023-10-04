module Arkham.Enemy.Cards.WatcherFromAnotherDimension (
  watcherFromAnotherDimension,
  WatcherFromAnotherDimension (..),
)
where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Enemy.Runner
import Arkham.Placement

newtype WatcherFromAnotherDimension = WatcherFromAnotherDimension EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

watcherFromAnotherDimension :: EnemyCard WatcherFromAnotherDimension
watcherFromAnotherDimension = enemy WatcherFromAnotherDimension Cards.watcherFromAnotherDimension (5, Static 2, 5) (3, 0)

instance RunMessage WatcherFromAnotherDimension where
  runMessage msg e@(WatcherFromAnotherDimension attrs) = case msg of
    Revelation iid (isSource attrs -> True) -> do
      pushAll [PlaceEnemy (toId e) (StillInHand iid)]
      pure e
    _ -> WatcherFromAnotherDimension <$> runMessage msg attrs

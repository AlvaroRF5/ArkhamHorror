module Arkham.Enemy.Cards.RuthTurner
  ( ruthTurner
  , RuthTurner(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Classes
import Arkham.Enemy.Runner
import Arkham.Matcher
import Arkham.Message hiding (EnemyEvaded)
import Arkham.Timing qualified as Timing

newtype RuthTurner = RuthTurner EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ruthTurner :: EnemyCard RuthTurner
ruthTurner = enemyWith
  RuthTurner
  Cards.ruthTurner
  (2, Static 4, 5)
  (1, 0)
  (spawnAtL ?~ LocationWithTitle "St. Mary's Hospital")

instance HasAbilities RuthTurner where
  getAbilities (RuthTurner a) = withBaseAbilities
    a
    [ mkAbility a 1
      $ ForcedAbility
      $ EnemyEvaded Timing.After Anyone
      $ EnemyWithId
      $ toId a
    ]

instance RunMessage RuthTurner where
  runMessage msg e@(RuthTurner attrs) = case msg of
    UseCardAbility _ source 1 _ _ | isSource attrs source ->
      e <$ push (AddToVictory $ toTarget attrs)
    _ -> RuthTurner <$> runMessage msg attrs

module Arkham.Enemy.Cards.BeingsOfIb (beingsOfIb, BeingsOfIb (..)) where

import Arkham.Classes
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Enemy.Runner
import Arkham.Prelude

newtype BeingsOfIb = BeingsOfIb EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks, NFData, HasAbilities)

beingsOfIb :: EnemyCard BeingsOfIb
beingsOfIb = enemy BeingsOfIb Cards.beingsOfIb (4, Static 1, 4) (0, 1)

instance RunMessage BeingsOfIb where
  runMessage msg (BeingsOfIb attrs) =
    BeingsOfIb <$> runMessage msg attrs

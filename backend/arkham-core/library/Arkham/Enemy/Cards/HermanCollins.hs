module Arkham.Enemy.Cards.HermanCollins
  ( HermanCollins(..)
  , hermanCollins
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Action hiding (Ability)
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Enemy.Runner
import Arkham.Matcher
import Arkham.Message

newtype HermanCollins = HermanCollins EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

hermanCollins :: EnemyCard HermanCollins
hermanCollins = enemyWith
  HermanCollins
  Cards.hermanCollins
  (3, Static 4, 4)
  (1, 1)
  (spawnAtL ?~ LocationWithTitle "Graveyard")

instance HasAbilities HermanCollins where
  getAbilities (HermanCollins attrs) = withBaseAbilities
    attrs
    [ restrictedAbility attrs 1 OnSameLocation $ ActionAbility
        (Just Parley)
        (Costs [ActionCost 1, HandDiscardCost 4 AnyCard])
    ]

instance EnemyRunner env => RunMessage HermanCollins where
  runMessage msg e@(HermanCollins attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      e <$ push (AddToVictory $ toTarget attrs)
    _ -> HermanCollins <$> runMessage msg attrs

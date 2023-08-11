module Arkham.Enemy.Cards.CatacombsDocent (
  catacombsDocent,
  CatacombsDocent (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Enemy.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType

newtype CatacombsDocent = CatacombsDocent EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

catacombsDocent :: EnemyCard CatacombsDocent
catacombsDocent =
  enemyWith
    CatacombsDocent
    Cards.catacombsDocent
    (3, Static 2, 2)
    (0, 1)
    (spawnAtL ?~ SpawnLocation (NearestLocationToYou UnrevealedLocation))

instance HasAbilities CatacombsDocent where
  getAbilities (CatacombsDocent a) =
    withBaseAbilities
      a
      [ restrictedAbility a 1 (LocationExists UnrevealedLocation) $
          ActionAbility (Just Action.Parley) (ActionCost 1)
      ]

instance RunMessage CatacombsDocent where
  runMessage msg e@(CatacombsDocent attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $
        parley
          iid
          (toSource attrs)
          (toTarget attrs)
          SkillIntellect
          4
      pure e
    PassedSkillTest iid _ (isSource attrs -> True) SkillTestInitiatorTarget {} _ _ ->
      do
        unrevealedLocations <- selectList UnrevealedLocation
        push $
          chooseOne
            iid
            [ targetLabel
              location
              [LookAtRevealed iid (toSource attrs) (LocationTarget location)]
            | location <- unrevealedLocations
            ]
        pure e
    _ -> CatacombsDocent <$> runMessage msg attrs

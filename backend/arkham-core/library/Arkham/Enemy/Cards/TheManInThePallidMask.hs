module Arkham.Enemy.Cards.TheManInThePallidMask
  ( theManInThePallidMask
  , TheManInThePallidMask(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Location.Cards qualified as Locations
import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Enemy.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target

newtype TheManInThePallidMask = TheManInThePallidMask EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theManInThePallidMask :: EnemyCard TheManInThePallidMask
theManInThePallidMask = enemyWith
  TheManInThePallidMask
  Cards.theManInThePallidMask
  (4, Static 3, 4)
  (0, 1)
  (spawnAtL ?~ FarthestLocationFromAll Anywhere)

instance HasAbilities TheManInThePallidMask where
  getAbilities (TheManInThePallidMask a) = withBaseAbilities
    a
    [ restrictedAbility a 1 OnSameLocation
      $ ActionAbility (Just Action.Investigate)
      $ ActionCost 1
    ]

instance EnemyRunner env => RunMessage env TheManInThePallidMask where
  runMessage msg e@(TheManInThePallidMask attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      lid <- getId iid
      e <$ pushAll
        [ skillTestModifier source (LocationTarget lid) (ShroudModifier 2)
        , Investigate
          iid
          lid
          source
          (Just $ toTarget attrs)
          SkillIntellect
          False
        ]
    Successful (Action.Investigate, _) iid _ target _ | isTarget attrs target -> do
      -- Tomb of Shadows will prevent the man in the pallid mask from being
      -- defeated, but because we have no good way of cancelling an aspect of
      -- an ability, we handle it here
      canBeDefeated <- case enemyLocation attrs of
        Just lid -> notMember lid <$> select (locationIs Locations.tombOfShadows)
        _ -> pure True
      when canBeDefeated $ push (DefeatEnemy (toId attrs) iid (toSource attrs))
      pure e
    _ -> TheManInThePallidMask <$> runMessage msg attrs

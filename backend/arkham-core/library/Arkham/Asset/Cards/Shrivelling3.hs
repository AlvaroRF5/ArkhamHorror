module Arkham.Asset.Cards.Shrivelling3
  ( Shrivelling3(..)
  , shrivelling3
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target

newtype Shrivelling3 = Shrivelling3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

shrivelling3 :: AssetCard Shrivelling3
shrivelling3 = asset Shrivelling3 Cards.shrivelling3

instance HasAbilities Shrivelling3 where
  getAbilities (Shrivelling3 a) =
    [ restrictedAbility a 1 OwnsThis $ ActionAbility
        (Just Action.Fight)
        (Costs [ActionCost 1, UseCost (toId a) Charge 1])
    ]

instance AssetRunner env => RunMessage env Shrivelling3 where
  runMessage msg a@(Shrivelling3 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifiers
        attrs
        (InvestigatorTarget iid)
        [SkillModifier SkillWillpower 2, DamageDealt 1]
      , CreateEffect "01060" Nothing source (InvestigatorTarget iid)
      -- reusing shrivelling(0)'s effect
      , ChooseFightEnemy iid source Nothing SkillWillpower mempty False
      ]
    _ -> Shrivelling3 <$> runMessage msg attrs

module Arkham.Asset.Cards.FireExtinguisher1 where

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

newtype FireExtinguisher1 = FireExtinguisher1 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fireExtinguisher1 :: AssetCard FireExtinguisher1
fireExtinguisher1 = asset FireExtinguisher1 Cards.fireExtinguisher1

instance HasAbilities FireExtinguisher1 where
  getAbilities (FireExtinguisher1 a) =
    [ restrictedAbility a 1 OwnsThis
      $ ActionAbility (Just Action.Fight) (ActionCost 1)
    , restrictedAbility a 2 OwnsThis $ ActionAbility
      (Just Action.Evade)
      (Costs [ActionCost 1, ExileCost $ toTarget a])
    ]

instance RunMessage FireExtinguisher1 where
  runMessage msg a@(FireExtinguisher1 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifier
        attrs
        (InvestigatorTarget iid)
        (SkillModifier SkillCombat 1)
      , ChooseFightEnemy iid source Nothing SkillCombat mempty False
      ]
    _ -> FireExtinguisher1 <$> runMessage msg attrs

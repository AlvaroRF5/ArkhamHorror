module Arkham.Asset.Cards.BloodstainedDagger (
  bloodstainedDagger,
  BloodstainedDagger (..),
)
where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner

newtype BloodstainedDagger = BloodstainedDagger AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

bloodstainedDagger :: AssetCard BloodstainedDagger
bloodstainedDagger =
  asset BloodstainedDagger Cards.bloodstainedDagger

instance HasAbilities BloodstainedDagger where
  getAbilities (BloodstainedDagger a) =
    [ withTooltip "{action}: _Fight_. You get +2 {combat} for this attack."
        $ restrictedAbility a 1 ControlsThis fightAction_
    , withTooltip
        "{action}: Exhaust Bloodstained Dagger and take 1 horror: _Fight_. You get +2 {combat} and deal +1 damage for this attack. If this attack defeats an enemy, draw 1 card."
        $ restrictedAbility a 2 ControlsThis
        $ fightAction (exhaust a <> HorrorCost (toSource a) YouTarget 1)
    ]

instance RunMessage BloodstainedDagger where
  runMessage msg a@(BloodstainedDagger attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      pushAll
        [ skillTestModifier attrs iid (SkillModifier #combat 2)
        , chooseFightEnemy iid (toAbilitySource attrs 1) #combat
        ]
      pure a
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      pushAll
        [ skillTestModifiers attrs iid [SkillModifier #combat 2, DamageDealt 1]
        , chooseFightEnemy iid (toAbilitySource attrs 2) #combat
        ]
      pure a
    EnemyDefeated _ _ (isAbilitySource attrs 2 -> True) _ -> do
      for_ (assetController attrs) $ \iid -> do
        pushM $ drawCards iid (toAbilitySource attrs 2) 1
      pure a
    _ -> BloodstainedDagger <$> runMessage msg attrs

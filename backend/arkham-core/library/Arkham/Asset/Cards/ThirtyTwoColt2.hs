module Arkham.Asset.Cards.ThirtyTwoColt2 (
  thirtyTwoColt2,
  ThirtyTwoColt2 (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner

newtype ThirtyTwoColt2 = ThirtyTwoColt2 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

thirtyTwoColt2 :: AssetCard ThirtyTwoColt2
thirtyTwoColt2 = asset ThirtyTwoColt2 Cards.thirtyTwoColt2

instance HasAbilities ThirtyTwoColt2 where
  getAbilities (ThirtyTwoColt2 a) =
    [ fightAbility a 1 (assetUseCost a Ammo 1) ControlsThis
    , restrictedAbility a 2 ControlsThis $ FastAbility $ ResourceCost 1
    ]

instance RunMessage ThirtyTwoColt2 where
  runMessage msg a@(ThirtyTwoColt2 attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      pushAll
        [ skillTestModifier (toAbilitySource attrs 1) iid (DamageDealt 1)
        , chooseFightEnemy iid (toAbilitySource attrs 1) #combat
        ]
      pure a
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      push $ ReturnToHand iid (toTarget attrs)
      pure a
    _ -> ThirtyTwoColt2 <$> runMessage msg attrs

module Arkham.Asset.Cards.SawedOffShotgun5 (
  SawedOffShotgun5 (..),
  sawedOffShotgun5,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Effect.Window
import Arkham.EffectMetadata

newtype SawedOffShotgun5 = SawedOffShotgun5 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sawedOffShotgun5 :: AssetCard SawedOffShotgun5
sawedOffShotgun5 = asset SawedOffShotgun5 Cards.sawedOffShotgun5

instance HasAbilities SawedOffShotgun5 where
  getAbilities (SawedOffShotgun5 a) = [fightAbility a 1 (assetUseCost a Ammo 1) ControlsThis]

instance RunMessage SawedOffShotgun5 where
  runMessage msg a@(SawedOffShotgun5 attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      push $ chooseFightEnemy iid (toAbilitySource attrs 1) #combat
      pure a
    FailedThisSkillTestBy iid (isAbilitySource attrs 1 -> True) n -> do
      -- This has to be handled specially for cards like Oops!
      let val = max 1 (min 6 n)
      push
        $ CreateWindowModifierEffect
          EffectSkillTestWindow
          (FailedByEffectModifiers $ toModifiers (toAbilitySource attrs 1) [DamageDealt val])
          (toAbilitySource attrs 1)
          (toTarget iid)
      pure a
    PassedThisSkillTestBy iid (isAbilitySource attrs 1 -> True) n -> do
      push $ skillTestModifier (toAbilitySource attrs 1) iid (DamageDealt $ max 1 (min 6 n))
      pure a
    _ -> SawedOffShotgun5 <$> runMessage msg attrs

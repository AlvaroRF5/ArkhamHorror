module Arkham.Asset.Cards.Rolands38Special (
  Rolands38Special (..),
  rolands38Special,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Matcher

newtype Rolands38Special = Rolands38Special AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rolands38Special :: AssetCard Rolands38Special
rolands38Special = asset Rolands38Special Cards.rolands38Special

instance HasAbilities Rolands38Special where
  getAbilities (Rolands38Special x) =
    [restrictedAbility x 1 ControlsThis $ fightAction $ assetUseCost x Ammo 1]

instance RunMessage Rolands38Special where
  runMessage msg a@(Rolands38Special attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      anyClues <- selectAny $ locationWithInvestigator iid <> LocationWithAnyClues
      let source = toAbilitySource attrs 1
      pushAll
        [ skillTestModifiers source iid [DamageDealt 1, SkillModifier #combat (if anyClues then 3 else 1)]
        , chooseFightEnemy iid source #combat
        ]
      pure a
    _ -> Rolands38Special <$> runMessage msg attrs

module Arkham.Asset.Cards.EighteenDerringer
  ( eighteenDerringer
  , EighteenDerringer(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.SkillType
import Arkham.Target

newtype EighteenDerringer = EighteenDerringer AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

eighteenDerringer :: AssetCard EighteenDerringer
eighteenDerringer = asset EighteenDerringer Cards.eighteenDerringer

instance HasAbilities EighteenDerringer where
  getAbilities (EighteenDerringer attrs) =
    [ restrictedAbility attrs 1 ControlsThis
        $ ActionAbility (Just Action.Fight)
        $ Costs [ActionCost 1, UseCost (AssetWithId $ toId attrs) Ammo 1]
    ]

instance RunMessage EighteenDerringer where
  runMessage msg a@(EighteenDerringer attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifiers
        attrs
        (InvestigatorTarget iid)
        [DamageDealt 1, SkillModifier SkillCombat 2]
      , ChooseFightEnemy iid source Nothing SkillCombat mempty False
      ]
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        pushAll [AddUses (toTarget attrs) Ammo 1]
        pure a
    _ -> EighteenDerringer <$> runMessage msg attrs

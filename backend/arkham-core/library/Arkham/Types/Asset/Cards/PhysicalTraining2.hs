module Arkham.Types.Asset.Cards.PhysicalTraining2
  ( PhysicalTraining2(..)
  , physicalTraining2
  ) where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner

newtype PhysicalTraining2 = PhysicalTraining2 AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

physicalTraining2 :: AssetId -> PhysicalTraining2
physicalTraining2 uuid = PhysicalTraining2 $ baseAttrs uuid "50001"

instance HasModifiersFor env PhysicalTraining2 where
  getModifiersFor = noModifiersFor

ability :: Int -> AssetAttrs -> Ability
ability idx a = mkAbility (toSource a) idx (FastAbility $ ResourceCost 1)

instance HasActions env PhysicalTraining2 where
  getActions iid (WhenSkillTest SkillWillpower) (PhysicalTraining2 a) =
    pure [ ActivateCardAbilityAction iid (ability 1 a) | ownedBy a iid ]
  getActions iid (WhenSkillTest SkillCombat) (PhysicalTraining2 a) =
    pure [ ActivateCardAbilityAction iid (ability 2 a) | ownedBy a iid ]
  getActions _ _ _ = pure []

instance (AssetRunner env) => RunMessage env PhysicalTraining2 where
  runMessage msg a@(PhysicalTraining2 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ unshiftMessage
        (CreateWindowModifierEffect
          EffectSkillTestWindow
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillWillpower 1])
          source
          (InvestigatorTarget iid)
        )
    UseCardAbility iid source _ 2 _ | isSource attrs source ->
      a <$ unshiftMessage
        (CreateWindowModifierEffect
          EffectSkillTestWindow
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillCombat 1])
          source
          (InvestigatorTarget iid)
        )
    _ -> PhysicalTraining2 <$> runMessage msg attrs

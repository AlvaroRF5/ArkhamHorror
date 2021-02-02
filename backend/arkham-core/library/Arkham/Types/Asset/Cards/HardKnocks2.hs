module Arkham.Types.Asset.Cards.HardKnocks2
  ( HardKnocks2(..)
  , hardKnocks2
  )
where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner

newtype HardKnocks2 = HardKnocks2 Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

hardKnocks2 :: AssetId -> HardKnocks2
hardKnocks2 uuid = HardKnocks2 $ baseAttrs uuid "50005"

instance HasModifiersFor env HardKnocks2 where
  getModifiersFor = noModifiersFor

ability :: Int -> Attrs -> Ability
ability idx a = mkAbility (toSource a) idx (FastAbility $ ResourceCost 1)

instance HasActions env HardKnocks2 where
  getActions iid (WhenSkillTest SkillCombat) (HardKnocks2 a) =
    pure [ ActivateCardAbilityAction iid (ability 1 a) | ownedBy a iid ]
  getActions iid (WhenSkillTest SkillAgility) (HardKnocks2 a) =
    pure [ ActivateCardAbilityAction iid (ability 2 a) | ownedBy a iid ]
  getActions _ _ _ = pure []

instance AssetRunner env => RunMessage env HardKnocks2 where
  runMessage msg a@(HardKnocks2 attrs@Attrs {..}) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ unshiftMessage
        (CreateWindowModifierEffect EffectSkillTestWindow
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillCombat 1])
          source
          (InvestigatorTarget iid)
        )
    UseCardAbility iid source _ 2 _ | isSource attrs source ->
      a <$ unshiftMessage
        (CreateWindowModifierEffect EffectSkillTestWindow
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillAgility 1])
          source
          (InvestigatorTarget iid)
        )
    _ -> HardKnocks2 <$> runMessage msg attrs

module Arkham.Types.Skill.Cards.ViciousBlow where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Game.Helpers
import Arkham.Types.Skill.Attrs
import Arkham.Types.Skill.Runner

newtype ViciousBlow = ViciousBlow Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

viciousBlow :: InvestigatorId -> SkillId -> ViciousBlow
viciousBlow iid uuid = ViciousBlow $ baseAttrs iid uuid "01025"

instance HasModifiersFor env ViciousBlow where
  getModifiersFor = noModifiersFor

instance HasActions env ViciousBlow where
  getActions i window (ViciousBlow attrs) = getActions i window attrs

instance (SkillRunner env) => RunMessage env ViciousBlow where
  runMessage msg s@(ViciousBlow attrs@Attrs {..}) = case msg of
    PassedSkillTest iid (Just Fight) _ (SkillTarget sid) _ _ | sid == skillId ->
      s <$ unshiftMessage
        (CreateWindowModifierEffect
          EffectSkillTestWindow
          (EffectModifiers $ toModifiers attrs [DamageDealt 1])
          (SkillSource skillId)
          (InvestigatorTarget iid)
        )
    _ -> ViciousBlow <$> runMessage msg attrs

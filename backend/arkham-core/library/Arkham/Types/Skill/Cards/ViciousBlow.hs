{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Skill.Cards.ViciousBlow where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Skill.Attrs
import Arkham.Types.Skill.Runner

newtype ViciousBlow = ViciousBlow Attrs
  deriving newtype (Show, ToJSON, FromJSON)

viciousBlow :: InvestigatorId -> SkillId -> ViciousBlow
viciousBlow iid uuid = ViciousBlow $ baseAttrs iid uuid "01025"

instance HasActions env ViciousBlow where
  getActions i window (ViciousBlow attrs) = getActions i window attrs

instance (SkillRunner env) => RunMessage env ViciousBlow where
  runMessage msg s@(ViciousBlow attrs@Attrs {..}) = case msg of
    PassedSkillTest iid (Just Fight) _ (SkillTarget sid) _ | sid == skillId ->
      s <$ unshiftMessage
        (CreateSkillTestEffect
          (EffectModifiers [DamageDealt 1])
          (SkillSource skillId)
          (InvestigatorTarget iid)
        )
    _ -> ViciousBlow <$> runMessage msg attrs

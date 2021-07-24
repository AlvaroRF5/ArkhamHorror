module Arkham.Types.Skill.Cards.Deduction where

import Arkham.Prelude

import qualified Arkham.Skill.Cards as Cards
import qualified Arkham.Types.Action as Action
import Arkham.Types.Classes
import Arkham.Types.EffectMetadata
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Skill.Attrs
import Arkham.Types.Skill.Runner
import Arkham.Types.Target

newtype Deduction = Deduction SkillAttrs
  deriving anyclass IsSkill
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

deduction :: SkillCard Deduction
deduction = skill Deduction Cards.deduction

instance HasModifiersFor env Deduction

instance HasActions env Deduction where
  getActions i window (Deduction attrs) = getActions i window attrs

instance (SkillRunner env) => RunMessage env Deduction where
  runMessage msg s@(Deduction attrs@SkillAttrs {..}) = case msg of
    PassedSkillTest iid (Just Action.Investigate) _ (SkillTarget sid) _ _
      | sid == skillId -> do
        lid <- getId @LocationId iid
        s <$ push
          (CreateEffect
            "01039"
            (Just $ EffectMetaTarget (LocationTarget lid))
            (toSource attrs)
            (InvestigatorTarget iid)
          )
    _ -> Deduction <$> runMessage msg attrs

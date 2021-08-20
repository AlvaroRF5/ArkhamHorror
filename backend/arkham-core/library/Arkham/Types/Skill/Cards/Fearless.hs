module Arkham.Types.Skill.Cards.Fearless where

import Arkham.Prelude

import qualified Arkham.Skill.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Skill.Attrs
import Arkham.Types.Target

newtype Fearless = Fearless SkillAttrs
  deriving anyclass (IsSkill, HasModifiersFor env, HasAbilities env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fearless :: SkillCard Fearless
fearless = skill Fearless Cards.fearless

instance RunMessage env Fearless where
  runMessage msg s@(Fearless attrs@SkillAttrs {..}) = case msg of
    PassedSkillTest _ _ _ (SkillTarget sid) _ _ | sid == skillId ->
      s <$ push (HealHorror (InvestigatorTarget skillOwner) 1)
    _ -> Fearless <$> runMessage msg attrs

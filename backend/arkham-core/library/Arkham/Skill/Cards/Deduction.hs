module Arkham.Skill.Cards.Deduction where

import Arkham.Prelude

import qualified Arkham.Action as Action
import Arkham.Classes
import Arkham.Message
import Arkham.Modifier
import Arkham.Helpers.Modifiers
import Arkham.Skill.Runner
import qualified Arkham.Skill.Cards as Cards
import Arkham.Target

newtype Deduction = Deduction SkillAttrs
  deriving anyclass (IsSkill, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

deduction :: SkillCard Deduction
deduction = skill Deduction Cards.deduction

instance RunMessage Deduction where
  runMessage msg s@(Deduction attrs@SkillAttrs {..}) = case msg of
    PassedSkillTest iid (Just Action.Investigate) _ (SkillTarget sid) _ _
      | sid == skillId -> do
        push $ skillTestModifier
          (toSource attrs)
          (InvestigatorTarget iid)
          (DiscoveredClues 1)
        pure s
    _ -> Deduction <$> runMessage msg attrs

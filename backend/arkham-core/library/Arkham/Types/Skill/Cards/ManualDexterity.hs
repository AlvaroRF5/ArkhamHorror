module Arkham.Types.Skill.Cards.ManualDexterity where

import Arkham.Prelude

import qualified Arkham.Skill.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Skill.Attrs
import Arkham.Types.Target

newtype ManualDexterity = ManualDexterity SkillAttrs
  deriving anyclass (IsSkill, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

manualDexterity :: SkillCard ManualDexterity
manualDexterity = skill ManualDexterity Cards.manualDexterity

instance RunMessage env ManualDexterity where
  runMessage msg s@(ManualDexterity attrs@SkillAttrs {..}) = case msg of
    PassedSkillTest _ _ _ (SkillTarget sid) _ _ | sid == skillId ->
      s <$ push (DrawCards skillOwner 1 False)
    _ -> ManualDexterity <$> runMessage msg attrs

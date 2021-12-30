module Arkham.Skill.Cards.Opportunist
  ( opportunist
  , Opportunist(..)
  ) where

import Arkham.Prelude

import Arkham.Skill.Cards qualified as Cards
import Arkham.Classes
import Arkham.Message
import Arkham.Skill.Attrs
import Arkham.Target

newtype Opportunist = Opportunist SkillAttrs
  deriving anyclass (IsSkill, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

opportunist :: SkillCard Opportunist
opportunist = skill Opportunist Cards.opportunist

instance RunMessage env Opportunist where
  runMessage msg s@(Opportunist attrs@SkillAttrs {..}) = case msg of
    PassedSkillTest iid _ _ (SkillTarget sid) _ n | sid == skillId && n >= 3 ->
      s <$ push (ReturnToHand iid (SkillTarget skillId))
    _ -> Opportunist <$> runMessage msg attrs

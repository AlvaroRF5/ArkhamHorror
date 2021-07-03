module Arkham.Types.Skill.Cards.Overpower where

import Arkham.Prelude

import qualified Arkham.Skill.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Skill.Attrs
import Arkham.Types.Skill.Runner
import Arkham.Types.Target

newtype Overpower = Overpower SkillAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

overpower :: SkillCard Overpower
overpower = skill Overpower Cards.overpower

instance HasModifiersFor env Overpower where
  getModifiersFor = noModifiersFor

instance HasActions env Overpower where
  getActions i window (Overpower attrs) = getActions i window attrs

instance (SkillRunner env) => RunMessage env Overpower where
  runMessage msg s@(Overpower attrs@SkillAttrs {..}) = case msg of
    PassedSkillTest _ _ _ (SkillTarget sid) _ _ | sid == skillId ->
      s <$ unshiftMessage (DrawCards skillOwner 1 False)
    _ -> Overpower <$> runMessage msg attrs

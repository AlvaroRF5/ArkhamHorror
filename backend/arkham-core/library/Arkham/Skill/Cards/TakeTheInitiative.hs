module Arkham.Skill.Cards.TakeTheInitiative (
  takeTheInitiative,
  TakeTheInitiative (..),
) where

import Arkham.Prelude

import Arkham.Classes
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Modifiers
import Arkham.History
import Arkham.Matcher
import Arkham.Skill.Cards qualified as Cards
import Arkham.Skill.Runner
import Arkham.SkillType

newtype TakeTheInitiative = TakeTheInitiative SkillAttrs
  deriving anyclass (IsSkill, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks, NFData)

takeTheInitiative :: SkillCard TakeTheInitiative
takeTheInitiative = skill TakeTheInitiative Cards.takeTheInitiative

instance HasModifiersFor TakeTheInitiative where
  getModifiersFor target (TakeTheInitiative a) | isTarget a target = do
    -- we want to include investigators that were eliminated
    iids <- selectList Anyone
    histories <- traverse (getHistory PhaseHistory) iids
    let total = sum $ map historyActionsCompleted histories
    pure
      $ toModifiers
        a
        [RemoveSkillIcons $ replicate (min 3 total) WildIcon | total > 0]
  getModifiersFor _ _ = pure []

instance RunMessage TakeTheInitiative where
  runMessage msg (TakeTheInitiative attrs) =
    TakeTheInitiative <$> runMessage msg attrs

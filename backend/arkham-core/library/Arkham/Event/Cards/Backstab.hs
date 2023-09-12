module Arkham.Event.Cards.Backstab where

import Arkham.Prelude

import Arkham.Action
import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Helpers
import Arkham.Event.Runner
import Arkham.Message
import Arkham.SkillType

newtype Backstab = Backstab EventAttrs
  deriving anyclass (IsEvent, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

backstab :: EventCard Backstab
backstab = event Backstab Cards.backstab

instance HasModifiersFor Backstab where
  getModifiersFor (InvestigatorTarget _) (Backstab attrs) = do
    mSource <- getSkillTestSource
    mAction <- getSkillTestAction
    pure $ case (mAction, mSource) of
      (Just Fight, Just (isSource attrs -> True)) -> do
        toModifiers attrs [DamageDealt 2]
      _ -> []
  getModifiersFor _ _ = pure []

instance RunMessage Backstab where
  runMessage msg e@(Backstab attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      push $ ChooseFightEnemy iid (toSource eid) Nothing SkillAgility mempty False
      pure e
    _ -> Backstab <$> runMessage msg attrs

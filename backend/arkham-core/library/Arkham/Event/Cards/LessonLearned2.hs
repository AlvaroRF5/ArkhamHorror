module Arkham.Event.Cards.LessonLearned2
  ( lessonLearned2
  , LessonLearned2(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Message

newtype LessonLearned2 = LessonLearned2 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

lessonLearned2 :: EventCard LessonLearned2
lessonLearned2 = event LessonLearned2 Cards.lessonLearned2

instance RunMessage LessonLearned2 where
  runMessage msg e@(LessonLearned2 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      pushAll
        [ InvestigatorDiscoverCluesAtTheirLocation iid 2 Nothing
        , Discard (toTarget attrs)
        ]
      pure e
    _ -> LessonLearned2 <$> runMessage msg attrs

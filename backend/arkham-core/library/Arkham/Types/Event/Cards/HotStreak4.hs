module Arkham.Types.Event.Cards.HotStreak4 where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.Message
import Arkham.Types.Target

newtype HotStreak4 = HotStreak4 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

hotStreak4 :: EventCard HotStreak4
hotStreak4 = event HotStreak4 Cards.hotStreak4

instance EventRunner env => RunMessage env HotStreak4 where
  runMessage msg e@(HotStreak4 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ | eid == eventId ->
      e <$ pushAll [TakeResources iid 10 False, Discard (EventTarget eid)]
    _ -> HotStreak4 <$> runMessage msg attrs

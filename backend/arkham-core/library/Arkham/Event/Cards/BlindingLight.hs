module Arkham.Event.Cards.BlindingLight where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards (blindingLight)
import Arkham.Classes
import Arkham.Event.Attrs
import Arkham.Event.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Source
import Arkham.Target

newtype BlindingLight = BlindingLight EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

blindingLight :: EventCard BlindingLight
blindingLight = event BlindingLight Cards.blindingLight

instance EventRunner env => RunMessage BlindingLight where
  runMessage msg e@(BlindingLight attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> e <$ pushAll
      [ CreateEffect "01066" Nothing (toSource attrs) (InvestigatorTarget iid)
      , CreateEffect "01066" Nothing (toSource attrs) SkillTestTarget
      , ChooseEvadeEnemy
        iid
        (EventSource eid)
        Nothing
        SkillWillpower
        AnyEnemy
        False
      , Discard (EventTarget eid)
      ]
    _ -> BlindingLight <$> runMessage msg attrs

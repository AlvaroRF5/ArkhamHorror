module Arkham.Types.Event.Cards.BlindingLight where

import Arkham.Import

import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner

newtype BlindingLight = BlindingLight EventAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

blindingLight :: InvestigatorId -> EventId -> BlindingLight
blindingLight iid uuid = BlindingLight $ baseAttrs iid uuid "01066"

instance HasModifiersFor env BlindingLight where
  getModifiersFor = noModifiersFor

instance HasActions env BlindingLight where
  getActions i window (BlindingLight attrs) = getActions i window attrs

instance (EventRunner env) => RunMessage env BlindingLight where
  runMessage msg e@(BlindingLight attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> e <$ unshiftMessages
      [ CreateEffect "01066" Nothing (toSource attrs) (InvestigatorTarget iid)
      , CreateEffect "01066" Nothing (toSource attrs) SkillTestTarget
      , ChooseEvadeEnemy iid (EventSource eid) SkillWillpower False
      , Discard (EventTarget eid)
      ]
    _ -> BlindingLight <$> runMessage msg attrs

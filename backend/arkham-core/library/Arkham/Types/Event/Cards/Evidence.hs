module Arkham.Types.Event.Cards.Evidence where

import Arkham.Import

import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner

newtype Evidence = Evidence Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

evidence :: InvestigatorId -> EventId -> Evidence
evidence iid uuid = Evidence $ baseAttrs iid uuid "01022"

instance HasModifiersFor env Evidence where
  getModifiersFor = noModifiersFor

instance HasActions env Evidence where
  getActions i window (Evidence attrs) = getActions i window attrs

instance (EventRunner env) => RunMessage env Evidence where
  runMessage msg e@(Evidence attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      currentLocationId <- getId @LocationId iid
      locationClueCount <- unClueCount <$> getCount currentLocationId
      if locationClueCount > 0
        then e <$ unshiftMessages
          [ DiscoverCluesAtLocation iid currentLocationId 1
          , Discard (EventTarget eid)
          ]
        else e <$ unshiftMessages [Discard (EventTarget eid)]
    _ -> Evidence <$> runMessage msg attrs

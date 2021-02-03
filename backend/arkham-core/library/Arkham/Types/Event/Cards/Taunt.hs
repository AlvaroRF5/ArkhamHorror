module Arkham.Types.Event.Cards.Taunt
  ( taunt
  , Taunt(..)
  )
where

import Arkham.Import

import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner

newtype Taunt = Taunt EventAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

taunt :: InvestigatorId -> EventId -> Taunt
taunt iid uuid = Taunt $ baseAttrs iid uuid "02017"

instance HasActions env Taunt where
  getActions iid window (Taunt attrs) = getActions iid window attrs

instance HasModifiersFor env Taunt where
  getModifiersFor = noModifiersFor

instance (EventRunner env) => RunMessage env Taunt where
  runMessage msg e@(Taunt attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      lid <- getId @LocationId iid
      enemyIds <- getSetList lid
      e <$ unshiftMessage
        (chooseSome iid [ EngageEnemy iid enemyId False | enemyId <- enemyIds ])
    _ -> Taunt <$> runMessage msg attrs

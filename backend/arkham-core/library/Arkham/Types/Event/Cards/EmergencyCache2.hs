module Arkham.Types.Event.Cards.EmergencyCache2
  ( emergencyCache2
  , EmergencyCache2(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Message
import Arkham.Types.Target

newtype EmergencyCache2 = EmergencyCache2 EventAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

emergencyCache2 :: EventCard EmergencyCache2
emergencyCache2 = event EmergencyCache2 Cards.emergencyCache2

instance HasModifiersFor env EmergencyCache2 where
  getModifiersFor = noModifiersFor

instance HasActions env EmergencyCache2 where
  getActions i window (EmergencyCache2 attrs) = getActions i window attrs

instance HasQueue env => RunMessage env EmergencyCache2 where
  runMessage msg e@(EmergencyCache2 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ | eid == eventId -> e <$ pushAll
      [ TakeResources iid 3 False
      , DrawCards iid 1 False
      , Discard (EventTarget eid)
      ]
    _ -> EmergencyCache2 <$> runMessage msg attrs

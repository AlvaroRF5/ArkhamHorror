module Arkham.Event.Cards.WardOfProtection5
  ( wardOfProtection5
  , WardOfProtection5(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Classes
import Arkham.Event.Runner
import Arkham.Event.Runner
import Arkham.Message
import Arkham.Source
import Arkham.Target

newtype WardOfProtection5 = WardOfProtection5 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wardOfProtection5 :: EventCard WardOfProtection5
wardOfProtection5 = event WardOfProtection5 Cards.wardOfProtection5

instance RunMessage WardOfProtection5 where
  runMessage msg e@(WardOfProtection5 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> e <$ pushAll
      [ CancelNext DrawEncounterCardMessage
      , InvestigatorAssignDamage iid (EventSource eid) DamageAny 0 1
      , Discard (EventTarget eid)
      ]
    _ -> WardOfProtection5 <$> runMessage msg attrs

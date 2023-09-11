module Arkham.Event.Cards.WardOfProtection where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Message

newtype WardOfProtection = WardOfProtection EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wardOfProtection :: EventCard WardOfProtection
wardOfProtection = event WardOfProtection Cards.wardOfProtection

instance RunMessage WardOfProtection where
  runMessage msg e@(WardOfProtection attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      pushAll
        [ CancelNext (toSource attrs) RevelationMessage
        , assignHorror iid (toSource eid) 1
        ]
      pure e
    _ -> WardOfProtection <$> runMessage msg attrs

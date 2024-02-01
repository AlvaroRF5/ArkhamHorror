module Arkham.Event.Cards.FightOrFlight (
  fightOrFlight,
  FightOrFlight (..),
) where

import Arkham.Prelude

import Arkham.Card.CardCode
import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner

newtype FightOrFlight = FightOrFlight EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks)

fightOrFlight :: EventCard FightOrFlight
fightOrFlight = event FightOrFlight Cards.fightOrFlight

instance RunMessage FightOrFlight where
  runMessage msg e@(FightOrFlight attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      e
        <$ pushAll
          [ CreateEffect
              (toCardCode attrs)
              Nothing
              (toSource attrs)
              (InvestigatorTarget iid)
          ]
    _ -> FightOrFlight <$> runMessage msg attrs

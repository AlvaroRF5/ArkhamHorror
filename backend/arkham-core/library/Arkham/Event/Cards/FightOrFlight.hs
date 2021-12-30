module Arkham.Event.Cards.FightOrFlight
  ( fightOrFlight
  , FightOrFlight(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Card.CardCode
import Arkham.Classes
import Arkham.Event.Attrs
import Arkham.Event.Runner
import Arkham.Message
import Arkham.Target

newtype FightOrFlight = FightOrFlight EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fightOrFlight :: EventCard FightOrFlight
fightOrFlight = event FightOrFlight Cards.fightOrFlight

instance EventRunner env => RunMessage env FightOrFlight where
  runMessage msg e@(FightOrFlight attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      e <$ pushAll
        [ CreateEffect
          (toCardCode attrs)
          Nothing
          (toSource attrs)
          (InvestigatorTarget iid)
        , Discard (toTarget attrs)
        ]
    _ -> FightOrFlight <$> runMessage msg attrs

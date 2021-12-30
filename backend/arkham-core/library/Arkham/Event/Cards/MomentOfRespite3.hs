module Arkham.Event.Cards.MomentOfRespite3
  ( momentOfRespite3
  , MomentOfRespite3(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Classes
import Arkham.Event.Attrs
import Arkham.Message
import Arkham.Target

newtype MomentOfRespite3 = MomentOfRespite3 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

momentOfRespite3 :: EventCard MomentOfRespite3
momentOfRespite3 = event MomentOfRespite3 Cards.momentOfRespite3

instance RunMessage env MomentOfRespite3 where
  runMessage msg e@(MomentOfRespite3 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      e <$ pushAll
        [ HealHorror (InvestigatorTarget iid) 3
        , DrawCards iid 1 False
        , Discard (toTarget attrs)
        ]
    _ -> MomentOfRespite3 <$> runMessage msg attrs

module Arkham.Event.Cards.PreposterousSketches
  ( preposterousSketches
  , PreposterousSketches(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Classes
import Arkham.Event.Runner
import Arkham.Message

newtype PreposterousSketches = PreposterousSketches EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

preposterousSketches :: EventCard PreposterousSketches
preposterousSketches = event PreposterousSketches Cards.preposterousSketches

instance RunMessage PreposterousSketches where
  runMessage msg e@(PreposterousSketches attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      drawing <- drawCards iid attrs 3
      pushAll [drawing, Discard (toTarget attrs)]
      pure e
    _ -> PreposterousSketches <$> runMessage msg attrs

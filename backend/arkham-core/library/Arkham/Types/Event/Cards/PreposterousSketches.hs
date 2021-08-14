module Arkham.Types.Event.Cards.PreposterousSketches
  ( preposterousSketches
  , PreposterousSketches(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Message

newtype PreposterousSketches = PreposterousSketches EventAttrs
  deriving anyclass IsEvent
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

preposterousSketches :: EventCard PreposterousSketches
preposterousSketches = event PreposterousSketches Cards.preposterousSketches

instance HasAbilities env PreposterousSketches where
  getAbilities iid window (PreposterousSketches attrs) =
    getAbilities iid window attrs

instance HasModifiersFor env PreposterousSketches

instance RunMessage env PreposterousSketches where
  runMessage msg e@(PreposterousSketches attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ | eid == toId attrs -> do
      e <$ pushAll [DrawCards iid 3 False, Discard (toTarget attrs)]
    _ -> PreposterousSketches <$> runMessage msg attrs

module Arkham.Types.Event.Cards.DelveTooDeep
  ( delveTooDeep
  , DelveTooDeep(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Message

newtype DelveTooDeep = DelveTooDeep EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

delveTooDeep :: EventCard DelveTooDeep
delveTooDeep = event DelveTooDeep Cards.delveTooDeep

instance HasQueue env => RunMessage env DelveTooDeep where
  runMessage msg e@(DelveTooDeep attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent _ eid _ _ | eid == eventId -> do
      e <$ pushAll [AllDrawEncounterCard, AddToVictory (toTarget attrs)]
    _ -> DelveTooDeep <$> runMessage msg attrs

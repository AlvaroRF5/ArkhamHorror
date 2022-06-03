module Arkham.Agenda.Cards.TimeIsRunningShort
  ( TimeIsRunningShort(..)
  , timeIsRunningShort
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Agenda.Attrs
import Arkham.Agenda.Runner
import Arkham.Classes
import Arkham.Cost
import Arkham.GameValue
import Arkham.Message
import Arkham.Resolution

newtype TimeIsRunningShort = TimeIsRunningShort AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

timeIsRunningShort :: AgendaCard TimeIsRunningShort
timeIsRunningShort =
  agenda (2, A) TimeIsRunningShort Cards.timeIsRunningShort (Static 8)

instance HasAbilities TimeIsRunningShort where
  getAbilities (TimeIsRunningShort a) =
    [mkAbility a 1 $ ActionAbility (Just Action.Resign) (ActionCost 1)]

instance AgendaRunner env => RunMessage TimeIsRunningShort where
  runMessage msg a@(TimeIsRunningShort attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 2 B ->
      a <$ push (ScenarioResolution $ Resolution 2)
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      a <$ push (Resign iid)
    _ -> TimeIsRunningShort <$> runMessage msg attrs

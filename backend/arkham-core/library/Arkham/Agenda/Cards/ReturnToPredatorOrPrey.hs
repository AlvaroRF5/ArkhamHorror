module Arkham.Agenda.Cards.ReturnToPredatorOrPrey
  ( ReturnToPredatorOrPrey(..)
  , returnToPredatorOrPrey
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Action qualified as Action
import Arkham.Agenda.Attrs
import Arkham.Agenda.Runner
import Arkham.Card
import Arkham.Card.EncounterCard
import Arkham.Classes
import Arkham.Cost
import Arkham.GameValue
import Arkham.Message
import Arkham.Source

newtype ReturnToPredatorOrPrey = ReturnToPredatorOrPrey AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

returnToPredatorOrPrey :: AgendaCard ReturnToPredatorOrPrey
returnToPredatorOrPrey =
  agenda (1, A) ReturnToPredatorOrPrey Cards.returnToPredatorOrPrey (Static 6)

instance HasAbilities ReturnToPredatorOrPrey where
  getAbilities (ReturnToPredatorOrPrey attrs) =
    [mkAbility attrs 1 $ ActionAbility (Just Action.Resign) (ActionCost 1)]

instance RunMessage ReturnToPredatorOrPrey where
  runMessage msg a@(ReturnToPredatorOrPrey attrs@AgendaAttrs {..}) =
    case msg of
      AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
        narogath <- EncounterCard <$> genEncounterCard Enemies.narogath
        a <$ pushAll
          [ CreateEnemyEngagedWithPrey narogath
          , AdvanceAgendaDeck agendaDeckId (toSource attrs)
          ]
      UseCardAbility iid (AgendaSource aid) _ 1 _ | aid == agendaId -> do
        push (Resign iid)
        ReturnToPredatorOrPrey <$> runMessage msg attrs
      _ -> ReturnToPredatorOrPrey <$> runMessage msg attrs

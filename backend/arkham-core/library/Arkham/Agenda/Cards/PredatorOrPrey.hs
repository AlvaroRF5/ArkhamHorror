module Arkham.Agenda.Cards.PredatorOrPrey
  ( PredatorOrPrey(..)
  , predatorOrPrey
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

newtype PredatorOrPrey = PredatorOrPrey AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

predatorOrPrey :: AgendaCard PredatorOrPrey
predatorOrPrey = agenda (1, A) PredatorOrPrey Cards.predatorOrPrey (Static 6)

instance HasAbilities PredatorOrPrey where
  getAbilities (PredatorOrPrey attrs) =
    [mkAbility attrs 1 $ ActionAbility (Just Action.Resign) (ActionCost 1)]

instance (AgendaRunner env) => RunMessage PredatorOrPrey where
  runMessage msg a@(PredatorOrPrey attrs@AgendaAttrs {..}) = case msg of
    UseCardAbility iid (AgendaSource aid) _ 1 _ | aid == agendaId -> do
      push (Resign iid)
      PredatorOrPrey <$> runMessage msg attrs
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
      theMaskedHunter <- EncounterCard
        <$> genEncounterCard Enemies.theMaskedHunter
      a <$ pushAll
        [ CreateEnemyEngagedWithPrey theMaskedHunter
        , AdvanceAgendaDeck agendaDeckId (toSource attrs)
        ]
    _ -> PredatorOrPrey <$> runMessage msg attrs

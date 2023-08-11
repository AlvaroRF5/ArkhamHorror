module Arkham.Agenda.Cards.PredatorOrPrey (
  PredatorOrPrey (..),
  predatorOrPrey,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Runner
import Arkham.Agenda.Types
import Arkham.Card
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Message

newtype PredatorOrPrey = PredatorOrPrey AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

predatorOrPrey :: AgendaCard PredatorOrPrey
predatorOrPrey = agenda (1, A) PredatorOrPrey Cards.predatorOrPrey (Static 6)

instance HasAbilities PredatorOrPrey where
  getAbilities (PredatorOrPrey attrs) =
    [mkAbility attrs 1 $ ActionAbility (Just Action.Resign) (ActionCost 1)]

instance RunMessage PredatorOrPrey where
  runMessage msg a@(PredatorOrPrey attrs@AgendaAttrs {..}) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $ Resign iid
      pure a
    AdvanceAgenda aid | aid == agendaId && onSide B attrs -> do
      theMaskedHunter <- genCard Enemies.theMaskedHunter
      createTheMaskedHunter <- createEnemyEngagedWithPrey_ theMaskedHunter
      pushAll
        [ createTheMaskedHunter
        , AdvanceAgendaDeck agendaDeckId (toSource attrs)
        ]
      pure a
    _ -> PredatorOrPrey <$> runMessage msg attrs

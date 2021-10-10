module Arkham.Types.Agenda.Cards.TheFestivitiesBegin
  ( TheFestivitiesBegin
  , theFestivitiesBegin
  ) where

import Arkham.Prelude

import Arkham.Agenda.Cards qualified as Cards
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Helpers
import Arkham.Types.Agenda.Runner
import Arkham.Types.Card.EncounterCard
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Message

newtype TheFestivitiesBegin = TheFestivitiesBegin AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theFestivitiesBegin :: AgendaCard TheFestivitiesBegin
theFestivitiesBegin =
  agenda (1, A) TheFestivitiesBegin Cards.theFestivitiesBegin (Static 8)

instance AgendaRunner env => RunMessage env TheFestivitiesBegin where
  runMessage msg a@(TheFestivitiesBegin attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
      leadInvestigatorId <- getLeadInvestigatorId
      balefulReveler <- genEncounterCard Enemies.balefulReveler
      a <$ pushAll
        [ InvestigatorDrewEncounterCard leadInvestigatorId balefulReveler
        , AdvanceAgendaDeck agendaDeckId (toSource attrs)
        ]
    _ -> TheFestivitiesBegin <$> runMessage msg attrs

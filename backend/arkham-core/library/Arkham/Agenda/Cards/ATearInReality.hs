module Arkham.Agenda.Cards.ATearInReality
  ( ATearInReality(..)
  , aTearInReality
  ) where

import Arkham.Prelude

import Arkham.Agenda.Cards qualified as Cards
import Arkham.Scenarios.TheEssexCountyExpress.Helpers
import Arkham.Agenda.Attrs
import Arkham.Agenda.Helpers
import Arkham.Agenda.Runner
import Arkham.Classes
import Arkham.GameValue
import Arkham.LocationId
import Arkham.Message
import Arkham.Query

newtype ATearInReality = ATearInReality AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

aTearInReality :: AgendaCard ATearInReality
aTearInReality = agenda (1, A) ATearInReality Cards.aTearInReality (Static 4)

instance AgendaRunner env => RunMessage ATearInReality where
  runMessage msg a@(ATearInReality attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      investigatorIds <- getInvestigatorIds
      locationId <- getId @LocationId leadInvestigatorId
      lid <- leftmostLocation locationId
      a <$ pushAll
        (RemoveLocation lid
        : [ InvestigatorDiscardAllClues iid | iid <- investigatorIds ]
        <> [AdvanceAgendaDeck agendaDeckId (toSource attrs)]
        )
    _ -> ATearInReality <$> runMessage msg attrs

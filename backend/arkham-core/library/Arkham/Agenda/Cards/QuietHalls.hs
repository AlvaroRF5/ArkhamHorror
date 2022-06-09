module Arkham.Agenda.Cards.QuietHalls where

import Arkham.Prelude

import Arkham.Agenda.Attrs
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Runner
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Helpers.Campaign
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Message
import Arkham.Projection

newtype QuietHalls = QuietHalls AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

quietHalls :: AgendaCard QuietHalls
quietHalls = agenda (1, A) QuietHalls Cards.quietHalls (Static 7)

instance RunMessage QuietHalls where
  runMessage msg a@(QuietHalls attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
      leadInvestigatorId <- getLeadInvestigatorId
      investigatorIds <- getInvestigatorIds
      completedTheHouseAlwaysWins <- elem "02062" <$> getCompletedScenarios
      messages <- flip mapMaybeM investigatorIds $ \iid -> do
        discardCount <- fieldF InvestigatorDiscard length iid
        if discardCount >= 5
          then pure $ Just
            (InvestigatorAssignDamage
              iid
              (toSource attrs)
              DamageAny
              0
              (if discardCount >= 10 then 2 else 1)
            )
          else pure Nothing

      pushAll messages

      let
        continueMessages = if completedTheHouseAlwaysWins
          then
            [ AdvanceAgendaDeck agendaDeckId (toSource attrs)
            , AdvanceCurrentAgenda
            ]
          else [AdvanceAgendaDeck agendaDeckId (toSource attrs)]

      a <$ push
        (chooseOne leadInvestigatorId [Label "Continue" continueMessages])
    _ -> QuietHalls <$> runMessage msg attrs

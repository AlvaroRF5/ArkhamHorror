module Arkham.Types.Agenda.Cards.ATearInReality
  ( ATearInReality(..)
  , aTearInReality
  )
where

import Arkham.Prelude

import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Helpers
import Arkham.Types.Agenda.Runner
import Arkham.Types.Classes
import Arkham.Types.Direction
import Arkham.Types.GameValue
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Query

newtype ATearInReality = ATearInReality AgendaAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

aTearInReality :: ATearInReality
aTearInReality =
  ATearInReality $ baseAttrs "02160" "A Tear in Reality" (Agenda 1 A) (Static 4)

instance HasModifiersFor env ATearInReality where
  getModifiersFor = noModifiersFor

instance HasActions env ATearInReality where
  getActions i window (ATearInReality x) = getActions i window x

leftmostLocation
  :: ( MonadReader env m
     , HasId (Maybe LocationId) env (Direction, LocationId)
     , MonadIO m
     )
  => LocationId
  -> m LocationId
leftmostLocation lid = do
  mlid' <- getId (LeftOf, lid)
  maybe (pure lid) leftmostLocation mlid'

instance AgendaRunner env => RunMessage env ATearInReality where
  runMessage msg a@(ATearInReality attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      investigatorIds <- getInvestigatorIds
      locationId <- getId @LocationId leadInvestigatorId
      lid <- leftmostLocation locationId
      a <$ pushAll
        (RemoveLocation lid
        : [ InvestigatorDiscardAllClues iid | iid <- investigatorIds ]
        <> [NextAgenda agendaId "02161"]
        )
    _ -> ATearInReality <$> runMessage msg attrs

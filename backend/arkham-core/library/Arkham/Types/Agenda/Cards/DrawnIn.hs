module Arkham.Types.Agenda.Cards.DrawnIn
  ( DrawnIn(..)
  , drawnIn
  ) where

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

newtype DrawnIn = DrawnIn AgendaAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drawnIn :: DrawnIn
drawnIn = DrawnIn $ baseAttrs "02163" "Drawn In" (Agenda 4 A) (Static 3)

instance HasModifiersFor env DrawnIn where
  getModifiersFor = noModifiersFor

instance HasActions env DrawnIn where
  getActions i window (DrawnIn x) = getActions i window x

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

instance AgendaRunner env => RunMessage env DrawnIn where
  runMessage msg a@(DrawnIn attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 3 B -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      investigatorIds <- getInvestigatorIds
      locationId <- getId @LocationId leadInvestigatorId
      lid <- leftmostLocation locationId
      rlid <- fromJustNote "missing right" <$> getId (RightOf, lid)
      a <$ unshiftMessages
        (RemoveLocation lid
        : RemoveLocation rlid
        : [ InvestigatorDiscardAllClues iid | iid <- investigatorIds ]
        <> [NextAgenda agendaId "02164"]
        )
    _ -> DrawnIn <$> runMessage msg attrs

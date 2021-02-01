module Arkham.Types.Agenda.Cards.TheArkhamWoods where

import Arkham.Import

import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Runner
import Arkham.Types.Card.EncounterCardMatcher
import Arkham.Types.Trait

newtype TheArkhamWoods = TheArkhamWoods AgendaAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

theArkhamWoods :: TheArkhamWoods
theArkhamWoods =
  TheArkhamWoods $ baseAttrs "01143" "The Arkham Woods" (Agenda 1 A) (Static 4)

instance HasModifiersFor env TheArkhamWoods where
  getModifiersFor = noModifiersFor

instance HasActions env TheArkhamWoods where
  getActions i window (TheArkhamWoods x) = getActions i window x

instance AgendaRunner env => RunMessage env TheArkhamWoods where
  runMessage msg a@(TheArkhamWoods attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B ->
      a <$ unshiftMessage
        (Run
          [ ShuffleEncounterDiscardBackIn
          , DiscardEncounterUntilFirst
            (AgendaSource aid)
            (EncounterCardMatchByType (EnemyType, Just Monster))
          ]
        )
    RequestedEncounterCard (AgendaSource aid) mcard | aid == agendaId ->
      case mcard of
        Nothing -> a <$ unshiftMessage (NextAgenda aid "01144")
        Just card -> a <$ unshiftMessages
          [ SpawnEnemyAt (EncounterCard card) "01149"
          , PlaceDoom (CardIdTarget $ getCardId card) 1
          , NextAgenda aid "01144"
          ]
    _ -> TheArkhamWoods <$> runMessage msg attrs

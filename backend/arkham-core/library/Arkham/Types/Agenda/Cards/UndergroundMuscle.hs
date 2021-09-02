module Arkham.Types.Agenda.Cards.UndergroundMuscle
  ( UndergroundMuscle(..)
  , undergroundMuscle
  ) where

import Arkham.Prelude

import qualified Arkham.Agenda.Cards as Cards
import Arkham.EncounterSet
import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Helpers
import Arkham.Types.Agenda.Runner
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.EnemyId
import Arkham.Types.GameValue
import Arkham.Types.InvestigatorId
import Arkham.Types.Message
import Arkham.Types.Query
import Data.Maybe (fromJust)

newtype UndergroundMuscle = UndergroundMuscle AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

undergroundMuscle :: AgendaCard UndergroundMuscle
undergroundMuscle =
  agenda (2, A) UndergroundMuscle Cards.undergroundMuscle (Static 3)

instance AgendaRunner env => RunMessage env UndergroundMuscle where
  runMessage msg (UndergroundMuscle attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 2 B -> do
      laBellaLunaId <- getJustLocationIdByName "La Bella Luna"
      cloverClubLoungeId <- getJustLocationIdByName "Clover Club Lounge"
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      result <- shuffleM =<< gatherEncounterSet HideousAbominations
      let
        enemy = fromJust . headMay $ result
        rest = drop 1 result
      strikingFear <- gatherEncounterSet StrikingFear
      laBellaLunaInvestigators <- getSetList laBellaLunaId
      laBellaLunaEnemies <- getSetList @EnemyId laBellaLunaId
      unEngagedEnemiesAtLaBellaLuna <- filterM
        (\eid -> null <$> getSetList @InvestigatorId eid)
        laBellaLunaEnemies
      push
        (chooseOne
          leadInvestigatorId
          [ Label
              "Continue"
              ([ CreateEnemyAt (EncounterCard enemy) cloverClubLoungeId Nothing
               , ShuffleEncounterDiscardBackIn
               , ShuffleIntoEncounterDeck $ rest <> strikingFear
               ]
              <> [ MoveAction iid cloverClubLoungeId Free False
                 | iid <- laBellaLunaInvestigators
                 ]
              <> [ EnemyMove eid laBellaLunaId cloverClubLoungeId
                 | eid <- unEngagedEnemiesAtLaBellaLuna
                 ]
              <> [RemoveLocation laBellaLunaId, NextAgenda agendaId "02065"]
              )
          ]
        )
      pure
        $ UndergroundMuscle
        $ attrs
        & (sequenceL .~ Agenda 1 B)
        & (flippedL .~ True)
    _ -> UndergroundMuscle <$> runMessage msg attrs

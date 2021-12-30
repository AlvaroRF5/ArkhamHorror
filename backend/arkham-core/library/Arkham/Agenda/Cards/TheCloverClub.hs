module Arkham.Agenda.Cards.TheCloverClub
  ( TheCloverClub(..)
  , theCloverClub
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Attrs
import Arkham.Agenda.Runner
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Id
import Arkham.Keyword
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Trait

newtype TheCloverClub = TheCloverClub AgendaAttrs
  deriving anyclass IsAgenda
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theCloverClub :: AgendaCard TheCloverClub
theCloverClub = agenda (1, A) TheCloverClub Cards.theCloverClub (Static 4)

instance Query EnemyMatcher env => HasModifiersFor env TheCloverClub where
  getModifiersFor _ (EnemyTarget eid) (TheCloverClub attrs) | onSide A attrs =
    do
      isCriminal <- member eid <$> select (EnemyWithTrait Criminal)
      pure $ toModifiers attrs [ AddKeyword Aloof | isCriminal ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities TheCloverClub where
  getAbilities (TheCloverClub x) =
    [ mkAbility x 1 $ ForcedAbility $ EnemyDealtDamage
        Timing.When
        AnyDamageEffect
        (EnemyWithTrait Criminal)
        AnySource
    | onSide A x
    ]

instance AgendaRunner env => RunMessage env TheCloverClub where
  runMessage msg a@(TheCloverClub attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AdvanceAgenda $ toId attrs)
    AdvanceAgenda aid | aid == toId attrs && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      completedExtracurricularActivity <-
        elem "02041" . map unCompletedScenarioId <$> getSetList ()
      enemyIds <- selectList $ EnemyWithTrait Criminal

      let
        continueMessages =
          [ ShuffleEncounterDiscardBackIn
            , AdvanceAgendaDeck (agendaDeckId attrs) (toSource attrs)
            ]
            <> [ AdvanceCurrentAgenda | completedExtracurricularActivity ]

      a <$ pushAll
        (map EnemyCheckEngagement enemyIds
        <> [chooseOne leadInvestigatorId [Label "Continue" continueMessages]]
        )
    _ -> TheCloverClub <$> runMessage msg attrs

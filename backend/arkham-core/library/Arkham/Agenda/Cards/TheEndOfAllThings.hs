module Arkham.Agenda.Cards.TheEndOfAllThings
  ( TheEndOfAllThings
  , theEndOfAllThings
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Attrs
import Arkham.Agenda.Runner
import Arkham.Attack
import Arkham.Classes
import Arkham.EnemyId
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message hiding (EnemyDefeated)
import Arkham.Resolution
import Arkham.Timing qualified as Timing

newtype TheEndOfAllThings = TheEndOfAllThings AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theEndOfAllThings :: AgendaCard TheEndOfAllThings
theEndOfAllThings =
  agenda (4, A) TheEndOfAllThings Cards.theEndOfAllThings (Static 2)

instance HasAbilities TheEndOfAllThings where
  getAbilities (TheEndOfAllThings x) =
    [ mkAbility x 1 $ ForcedAbility $ MovedBy
      Timing.After
      You
      EncounterCardSource
    , mkAbility x 2
    $ ForcedAbility
    $ EnemyDefeated Timing.When Anyone
    $ EnemyWithTitle "Yog-Sothoth"
    ]

instance (HasId (Maybe EnemyId) env EnemyMatcher, AgendaRunner env) => RunMessage TheEndOfAllThings where
  runMessage msg a@(TheEndOfAllThings attrs@AgendaAttrs {..}) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (InvestigatorAssignDamage iid source DamageAny 0 1)
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      a <$ push (ScenarioResolution $ Resolution 3)
    AdvanceAgenda aid | aid == agendaId && onSide B attrs -> do
      investigatorIds <- getInvestigatorIds
      yogSothoth <- fromJustNote "defeated?"
        <$> getId (EnemyWithTitle "Yog-Sothoth")
      a <$ pushAll
        ([ EnemyAttack iid yogSothoth DamageAny RegularAttack | iid <- investigatorIds ]
        <> [RevertAgenda aid]
        )
    _ -> TheEndOfAllThings <$> runMessage msg attrs

module Arkham.Types.Window where

import Arkham.Prelude

import Arkham.Types.ActId
import Arkham.Types.Action
import Arkham.Types.AgendaId
import Arkham.Types.Card.CardCode
import Arkham.Types.Card.Id
import Arkham.Types.EnemyId
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Phase
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Token
import Arkham.Types.Trait
import Arkham.Types.TreacheryId

data Window
  = AfterDiscoveringClues Who Where -- name conflict resolution
  | AfterDrawCard Who CardId
  | AfterCommitedCard Who CardId
  | AfterEndTurn Who
  | AfterEnemyDefeated Who EnemyId
  | AfterEnemyEngageInvestigator Who EnemyId
  | AfterEnemyEvaded Who EnemyId
  | AfterFailAttackEnemy Who EnemyId
  | AfterFailInvestigationSkillTest Who Int
  | AfterFailSkillTest Who Int
  | AfterFailSkillTestAtOrLess Who Int
  | AfterLeaving Who LocationId
  | AfterMoveFromHunter EnemyId
  | AfterEntering Who LocationId
  | AfterPassSkillTest (Maybe Action) Source Who Int
  | AfterPlayCard Who [Trait]
  | AfterPutLocationIntoPlay Who
  | AfterRevealLocation Who
  | AfterSuccessfulAttackEnemy Who EnemyId
  | AfterSuccessfulInvestigation Who Where
  | AfterTurnBegins Who
  | AnyPhaseBegins
  | PhaseBegins Phase
  | PhaseEnds Phase
  | AtEndOfRound
  | DuringTurn Who
  | FastPlayerWindow
  | InDiscardWindow InvestigatorId Window
  | InHandWindow InvestigatorId Window
  | NonFast
  | WhenActAdvance ActId
  | WhenAgendaAdvance AgendaId
  | WhenAllDrawEncounterCard
  | WhenAmongSearchedCards Who
  | WhenChosenRandomLocation LocationId
  | WhenDealtDamage Source Target
  | WhenDealtHorror Source Target
  | WhenDefeated Source
  | WhenDiscoverClues Who Where
  | WhenDrawEncounterCard Who CardCode
  | WhenWouldDrawEncounterCard Who
  | WhenDrawNonPerilTreachery Who TreacheryId
  | WhenDrawToken Who Token
  | WhenDrawTreachery Who
  | WhenEnemyAttacks Who
  | WhenEnemyDefeated Who
  | WhenEnemyEvaded Who
  | WhenEnemySpawns EnemyId LocationId
  | WhenEnterPlay Target
  | WhenLocationLeavesPlay LocationId
  | WhenPlayCard Who CardId
  | WhenRevealToken Who Token
  | AfterRevealToken Who Token
  | WhenRevealTokenWithNegativeModifier Who Token
  | WhenSkillTest SkillType
  | WhenSuccessfulAttackEnemy Who EnemyId
  | WhenSuccessfulInvestigation Who Where
  | WhenTurnBegins Who
  | WhenWouldFailSkillTest Who
  | WhenWouldLeave Who LocationId
  | WhenWouldReady Target
  | WhenWouldRevealChaosToken Source Who
  | WhenWouldTakeDamage Source Target
  | WhenWouldTakeHorror Source Target
  | WhenWouldTakeDamageOrHorror Source Target Int Int
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, Hashable)

data Where = YourLocation | ConnectedLocation | LocationInGame
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, Hashable)

data Who = You | InvestigatorAtYourLocation | InvestigatorAtAConnectedLocation | InvestigatorInGame
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, Hashable)

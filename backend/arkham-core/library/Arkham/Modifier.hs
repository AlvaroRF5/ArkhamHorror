module Arkham.Modifier
  ( Modifier(..)
  , ModifierType(..)
  , ActionTarget(..)
  ) where

import Arkham.Prelude

import Arkham.Action
import Arkham.Action.Additional
import {-# SOURCE #-} Arkham.Card
import Arkham.Card.CardCode
import Arkham.Card.CardType
import Arkham.ChaosBag.RevealStrategy
import Arkham.ClassSymbol
import Arkham.Criteria.Override
import {-# SOURCE #-} Arkham.Cost
import Arkham.Id
import Arkham.Json
import Arkham.Keyword
import {-# SOURCE #-} Arkham.Matcher.Types
import Arkham.Phase
import Arkham.SkillType
import Arkham.SlotType
import {-# SOURCE #-} Arkham.Source
import {-# SOURCE #-} Arkham.Target
import Arkham.Token
import Arkham.Trait

data Modifier = Modifier
  { modifierSource :: Source
  , modifierType :: ModifierType
  }
  deriving stock (Show, Eq, Generic)
  deriving anyclass Hashable

data ModifierType
  = ActionCostOf ActionTarget Int
  | AbilityModifier Target Int ModifierType
  | SkillTestResultValueModifier Int
  | TraitRestrictedModifier Trait ModifierType
  | ActionCostModifier Int
  | ActionCostSetToModifier Int
  | ActionSkillModifier Action SkillType Int
  | ActionsAreFree
  | AddKeyword Keyword
  | AddTrait Trait
  | AddSkillIcons [SkillType]
  | RemoveSkillIcons [SkillType]
  | AdditionalActions Int
  | GiveAdditionalAction AdditionalAction
  | AdditionalStartingUses Int
  | AdditionalCost Cost
  | ChangeRevealStrategy RevealStrategy
  | CannotTriggerAbilityMatching AbilityMatcher
  | ConnectedToWhen LocationMatcher LocationMatcher
  | AlternateSuccessfullEvasion
  | AlternateSuccessfullInvestigation
  | AlternativeReady Source
  | AnySkillValue Int
  | AsIfInHand Card
  | AsIfUnderControlOf InvestigatorId
  | AttacksCannotBeCancelled
  | BaseSkillOf SkillType Int
  | BecomesFast
  | Blank
  | Blocked
  | CannotEnter LocationId
  | CanAssignDamageToAsset AssetId
  | CanBeAssignedDirectDamage
  | CanBeFoughtAsIfAtYourLocation
  | CanBecomeFast CardMatcher
  | CanCommitToSkillTestPerformedByAnInvestigatorAtAnotherLocation Int
  | CanOnlyBeAttackedByAbilityOn (HashSet CardCode)
  | CanOnlyUseCardsInRole ClassSymbol
  | CanPlayTopOfDiscard (Maybe CardType, [Trait])
  | CanPlayTopOfDeck CardMatcher
  | CanSpendResourcesOnCardFromInvestigator InvestigatorMatcher CardMatcher
  | CancelSkills
  | CannotAttack
  | CannotBeAttacked
  | CannotBeAttackedByNonElite
  | CannotBeFlipped
  | CannotBeDefeated
  | CanOnlyBeDefeatedBy Source
  | CanOnlyBeDefeatedByDamage
  | CancelAttacksByEnemies EnemyMatcher
  | CannotBeDamaged
  | CannotBeDamagedByPlayerSources SourceMatcher
  | CannotBeDamagedByPlayerSourcesExcept SourceMatcher
  | CannotBeDiscarded
  | CannotBeEnteredByNonElite
  | CannotBeEvaded
  | CannotBeRevealed
  | CannotCancelHorror
  | CannotCommitCards CardMatcher
  | CannotDiscoverClues
  | CannotDrawCards
  | CannotEngage InvestigatorId
  | CannotGainResources
  | CannotHealHorror
  | CannotExplore
  | CannotInvestigate
  | CannotInvestigateLocation LocationId
  | CannotMakeAttacksOfOpportunity
  | CannotManipulateDeck
  | ActionDoesNotCauseAttacksOfOpportunity Action
  | DoesNotReadyDuringUpkeep
  | CannotFight EnemyMatcher
  | CannotMove
  | CannotDisengageEnemies
  | CannotMoveMoreThanOnceEachTurn
  | CannotMulligan
  | CannotPerformSkillTest
  | CannotPlaceClues
  | CannotPlay CardMatcher
  | CannotSpendClues
  | MaxCluesDiscovered Int
  | CannotDiscoverCluesAt LocationMatcher
  | CannotTakeAction ActionTarget
  | CannotTakeControlOfClues
  | CannotTriggerFastAbilities
  | CardsCannotLeaveYourDiscardPile
  | ChangeTokenModifier TokenModifier
  | ControlledAssetsCannotReady
  | DamageDealt Int
  | DamageTaken Int
  | Difficulty Int
  | DiscoveredClues Int
  | DoNotRemoveDoom
  | DoNotDrawChaosTokensForSkillChecks
  | DoesNotDamageOtherInvestigator
  | DoomThresholdModifier Int
  | DoomSubtracts
  | DoubleDifficulty
  | DoubleNegativeModifiersOnTokens
  | DoubleSkillIcons
  | DoubleSuccess
  | DoubleBaseSkillValue
  | DuringEnemyPhaseMustMoveToward Target
  | EnemyCannotEngage InvestigatorId
  | EnemyEvade Int
  | EnemyFight Int
  | AsIfEnemyFight Int
  | FewerSlots SlotType Int
  | ForcedTokenChange TokenFace [TokenFace]
  | HandSize Int
  | IgnoreHandSizeReduction
  | HandSizeCardCount Int
  | HealthModifier Int
  | HorrorDealt Int
  | HunterConnectedTo LocationId
  | CanRetaliateWhileExhausted
  | IgnoreRetaliate
  | IgnoreText
  | IgnoreToken
  | IgnoreTokenEffects
  | IncreaseCostOf CardMatcher Int
  | KilledIfDefeated
  | MaxDamageTaken Int
  | MayChooseNotToTakeUpkeepResources
  | ModifierIfSucceededBy Int Modifier
  | NegativeToPositive
  | NoDamageDealt
  | NonDirectHorrorMustBeAssignToThisFirst
  | PlaceOnBottomOfDeckInsteadOfDiscard
  | ReduceCostOf CardMatcher Int
  | CanReduceCostOf CardMatcher Int
  | RemoveFromGameInsteadOfDiscard
  | RemoveKeyword Keyword
  | ReturnToHandAfterTest
  | SanityModifier Int
  | SetDifficulty Int
  | ShroudModifier Int
  | SkillModifier SkillType Int
  | AddSkillValue SkillType
  | SkillCannotBeIncreased SkillType
  | SkipMythosPhaseStep MythosPhaseStep
  | SpawnNonEliteAtConnectingInstead
  | SpawnLocation LocationMatcher
  | StartingResources Int
  | StartingClues Int
  | TokenFaceModifier [TokenFace]
  | TokenValueModifier Int
  | TopCardOfDeckIsRevealed
  | TreatAllDamageAsDirect
  | TreatRevealedTokenAs TokenFace
  | UseSkillInPlaceOf SkillType SkillType
  | XPModifier Int
  | SkillTestAutomaticallySucceeds
  | IgnoreRevelation
  | InVictoryDisplayForCountingVengeance
  | EnemyFightActionCriteria CriteriaOverride
  deriving stock (Show, Eq, Generic)
  deriving anyclass Hashable

data ActionTarget
  = FirstOneOf [Action]
  | IsAction Action
  | EnemyAction Action EnemyMatcher
  deriving stock (Show, Eq, Generic)
  deriving anyclass (FromJSON, ToJSON, Hashable)

instance ToJSON ModifierType where
  toJSON = genericToJSON defaultOptions

instance FromJSON ModifierType where
  parseJSON = genericParseJSON defaultOptions

instance ToJSON Modifier where
  toJSON = genericToJSON $ aesonOptions $ Just "modifier"
  toEncoding = genericToEncoding $ aesonOptions $ Just "modifier"

instance FromJSON Modifier where
  parseJSON = genericParseJSON $ aesonOptions $ Just "modifier"


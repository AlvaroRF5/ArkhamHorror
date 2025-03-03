{-# LANGUAGE TemplateHaskell #-}

module Arkham.Modifier where

import Arkham.Prelude

import Arkham.Action
import Arkham.Action.Additional
import Arkham.Asset.Uses
import {-# SOURCE #-} Arkham.Card (Card, CardCode)
import Arkham.Card.CardType
import Arkham.ChaosBag.RevealStrategy
import Arkham.ChaosToken
import Arkham.ClassSymbol
import {-# SOURCE #-} Arkham.Cost
import Arkham.Criteria.Override
import {-# SOURCE #-} Arkham.Enemy.Types
import Arkham.Field
import Arkham.Id
import Arkham.Json
import Arkham.Keyword
import {-# SOURCE #-} Arkham.Matcher.Types
import Arkham.Phase
import Arkham.Scenario.Deck
import Arkham.SkillType
import Arkham.SlotType
import {-# SOURCE #-} Arkham.Source
import {-# SOURCE #-} Arkham.Strategy
import {-# SOURCE #-} Arkham.Target
import Arkham.Trait
import Control.Lens (Prism', prism')
import Data.Aeson.TH
import GHC.OverloadedLabels

data ModifierType
  = AbilityModifier Target Int ModifierType
  | ActionCostModifier Int
  | ActionCostOf ActionTarget Int
  | ActionCostSetToModifier Int
  | ActionDoesNotCauseAttacksOfOpportunity Action
  | ActionSkillModifier {action :: Action, skillType :: SkillType, value :: Int}
  | ActionsAreFree
  | AddKeyword Keyword
  | AddSkillIcons [SkillIcon]
  | AddSkillToOtherSkill SkillType SkillType
  | AddSkillValue SkillType
  | AddTrait Trait
  | AdditionalActions Text Source Int
  | AdditionalCost Cost
  | AdditionalCostToEnter Cost
  | AdditionalCostToLeave Cost
  | AdditionalStartingUses Int
  | AdditionalStartingCards [Card]
  | AdditionalTargets Int
  | AlternateEvadeField (SomeField Enemy)
  | AlternateFightField (SomeField Enemy)
  | AlternateResourceCost CardMatcher Cost
  | AlternateSuccessfullEvasion
  | AlternateSuccessfullInvestigation Target
  | AlternateUpkeepDraw Target
  | AlternativeReady Source
  | AnySkillValue Int
  | AsIfAt LocationId
  | AsIfEnemyFight Int
  | AsIfEngagedWith EnemyId
  | AsIfInHand Card
  | AsIfUnderControlOf InvestigatorId
  | AttacksCannotBeCancelled
  | BaseSkillOf {skillType :: SkillType, value :: Int}
  | BecomesFast
  | Blank
  | BlankExceptForcedAbilities
  | Blocked
  | BondedInsteadOfDiscard
  | BondedInsteadOfShuffle
  | BountiesOnly
  | CanAssignDamageToAsset AssetId
  | CanAssignHorrorToAsset AssetId
  | CanBeAssignedDirectDamage
  | CanBeFoughtAsIfAtYourLocation
  | CanBecomeFast CardMatcher
  | CanBecomeFastOrReduceCostOf CardMatcher Int -- Used by Chuck Fergus (2), check for notes
  | CanCommitToSkillTestPerformedByAnInvestigatorAt LocationMatcher
  | CanCommitToSkillTestsAsIfInHand Card
  | CanEnterEmptySpace
  | CanIgnoreAspect AspectMatcher
  | CanIgnoreLimit
  | CanModify ModifierType
  | CanMoveWith InvestigatorMatcher
  | CanOnlyBeAttackedByAbilityOn (Set CardCode)
  | CanOnlyBeDefeatedBy SourceMatcher
  | CanOnlyBeDefeatedByDamage
  | CanOnlyUseCardsInRole ClassSymbol
  | CanPlayTopOfDeck CardMatcher
  | CanPlayTopmostOfDiscard (Maybe CardType, [Trait])
  | CanPlayWithOverride CriteriaOverride
  | CanReduceCostOf CardMatcher Int
  | CanResolveToken ChaosTokenFace Target
  | CanRetaliateWhileExhausted
  | CanSpendResourcesOnCardFromInvestigator InvestigatorMatcher CardMatcher
  | CanSpendUsesAsResourceOnCardFromInvestigator AssetId UseType InvestigatorMatcher CardMatcher
  | CancelAttacksByEnemies Card EnemyMatcher
  | CancelSkills
  | CannotAffectOtherPlayersWithPlayerEffectsExceptDamage
  | CannotAttack
  | CannotBeAdvancedByDoomThreshold
  | CannotBeAttacked
  | CannotBeAttackedBy EnemyMatcher
  | CannotBeDamaged
  | CannotBeDamagedByPlayerSources SourceMatcher
  | CannotBeDamagedByPlayerSourcesExcept SourceMatcher
  | CannotBeDefeated
  | CannotBeEngaged
  | CannotBeEngagedBy EnemyMatcher
  | CannotBeEnteredBy EnemyMatcher
  | CannotBeEvaded
  | CannotBeFlipped
  | CannotBeMoved
  | CannotBeRevealed
  | CannotCancelHorror
  | CannotCancelOrIgnoreChaosToken ChaosTokenFace
  | CannotCommitCards CardMatcher
  | CannotCommitToOtherInvestigatorsSkillTests
  | CannotDealDamage
  | CannotDiscoverClues
  | CannotDiscoverCluesAt LocationMatcher
  | CannotDisengageEnemies
  | CannotDrawCards
  | CannotEngage InvestigatorId
  | CannotEnter LocationId
  | CannotEvade EnemyMatcher
  | CannotExplore
  | CannotFight EnemyMatcher
  | CannotGainResources
  | CannotHealHorror
  | CannotHealHorrorOnOtherCards Target
  | CannotInvestigate
  | CannotInvestigateLocation LocationId
  | CannotMakeAttacksOfOpportunity
  | CannotManipulateDeck
  | CannotMove
  | CannotMoveMoreThanOnceEachTurn
  | CannotMulligan
  | CannotParleyWith EnemyMatcher
  | CannotPerformSkillTest
  | CannotPlaceClues
  | CannotPlaceDoomOnThis
  | CannotPlay CardMatcher
  | CannotPutIntoPlay CardMatcher
  | CannotReady
  | CannotReplaceWeaknesses
  | CannotSpawnIn LocationMatcher
  | CannotSpendClues
  | CannotTakeAction ActionTarget
  | CannotTakeControlOfClues
  | CannotTriggerAbilityMatching AbilityMatcher
  | CannotTriggerFastAbilities
  | CardsCannotLeaveYourDiscardPile
  | ChangeChaosTokenModifier ChaosTokenModifier
  | ChangeRevealStrategy RevealStrategy
  | ChaosTokenFaceModifier [ChaosTokenFace]
  | ChaosTokenValueModifier Int
  | CommitCost Cost
  | ConnectedToWhen LocationMatcher LocationMatcher
  | ControlledAssetsCannotReady
  | CountAllDoomInPlay
  | CountsAsInvestigatorForHunterEnemies
  | DamageDealt Int
  | DamageTaken Int
  | Difficulty Int
  | DiscoveredClues Int
  | DoNotDisengageEvaded
  | DoNotDrawChaosTokensForSkillChecks
  | DoNotExhaustEvaded
  | DoNotRemoveDoom
  | DoNotTakeUpSlot SlotType
  | DoesNotDamageOtherInvestigator
  | DoesNotReadyDuringUpkeep
  | DoomSubtracts
  | DoomThresholdModifier Int
  | DoubleBaseSkillValue
  | DoubleDifficulty
  | DoubleNegativeModifiersOnChaosTokens
  | DoubleSkillIcons
  | DoubleSuccess
  | DuringEnemyPhaseMustMoveToward Target
  | EffectsCannotBeCanceled
  | EnemyCannotEngage InvestigatorId
  | EnemyEvade Int
  | EnemyEvadeActionCriteria CriteriaOverride
  | EnemyEvadeWithMin Int (Min Int)
  | EnemyFight Int
  | EnemyFightActionCriteria CriteriaOverride
  | EnemyFightWithMin Int (Min Int)
  | EnemyEngageActionCriteria CriteriaOverride
  | FailTies
  | FewerActions Int
  | FewerSlots SlotType Int
  | ForcePrey PreyMatcher
  | ForceSpawnLocation LocationMatcher
  | ForcedChaosTokenChange ChaosTokenFace [ChaosTokenFace]
  | GainVictory Int
  | GiveAdditionalAction AdditionalAction
  | HandSize Int
  | CheckHandSizeAfterDraw
  | HandSizeCardCount Int
  | HealHorrorOnThisAsIfInvestigator InvestigatorId
  | HealthModifier Int
  | HealthModifierWithMin Int (Min Int)
  | HorrorDealt Int
  | HunterConnectedTo LocationId
  | IgnoreAllCosts
  | IgnoreAloof
  | IgnoreChaosToken
  | IgnoreChaosTokenEffects
  | IgnoreHandSizeReduction
  | IgnoreLimit
  | IgnorePlayableModifierContexts
  | IgnoreRetaliate
  | IgnoreRevelation
  | IgnoreText
  | InVictoryDisplayForCountingVengeance
  | IncreaseCostOf CardMatcher Int
  | IsEmptySpace
  | KilledIfDefeated
  | LeaveCardWhereItIs
  | LosePatrol
  | LoseVictory
  | MaxCluesDiscovered Int
  | MaxDamageTaken Int
  | MayChooseNotToTakeUpkeepResources
  | MayIgnoreLocationEffectsAndKeywords
  | MetaModifier Value
  | ModifierIfSucceededBy Int Modifier
  | Mulligans Int
  | MustBeCommitted
  | MustTakeAction ActionTarget
  | NegativeToPositive
  | NoDamageDealt
  | NoMoreThanOneDamageOrHorrorAmongst AssetMatcher
  | NoSurge
  | NonDirectHorrorMustBeAssignToThisFirst
  | Omnipotent
  | OnlyFirstCopyCardCountsTowardMaximumHandSize
  | PlaceOnBottomOfDeckInsteadOfDiscard
  | PlayableModifierContexts [(CardMatcher, [ModifierType])]
  | ReduceCostOf CardMatcher Int
  | RemoveFromGameInsteadOfDiscard
  | RemoveKeyword Keyword
  | RemoveSkillIcons [SkillIcon]
  | RemoveTrait Trait
  | ResolvesFailedEffects
  | ReturnToHandAfterTest
  | RevealAnotherChaosToken -- TODO: Only ShatteredAeons handles this, if a player card affects this, all scenarios have to be updated
  | RevealChaosTokensBeforeCommittingCards
  | SanityModifier Int
  | SearchDepth Int
  | SetAbilityCost Cost
  | SetAbilityCriteria CriteriaOverride
  | SetAfterPlay AfterPlayStrategy
  | SetDifficulty Int
  | SetShroud Int
  | SharesSlotWith Int CardMatcher -- card matcher allows us to check more easily from hand
  | ShroudModifier Int
  | SkillCannotBeIncreased SkillType
  | SkillModifier {skillType :: SkillType, value :: Int}
  | SkillModifiersAffectOtherSkill SkillType SkillType
  | SkillTestAutomaticallySucceeds
  | SkillTestResultValueModifier Int
  | SkipMythosPhaseStep MythosPhaseStep
  | SlotCanBe SlotType SlotType
  | SpawnNonEliteAtConnectingInstead
  | StartingClues Int
  | StartingHand Int
  | StartingResources Int
  | UpkeepResources Int
  | TopCardOfDeckIsRevealed
  | TraitRestrictedModifier Trait ModifierType
  | TreatAllDamageAsDirect
  | TreatRevealedChaosTokenAs ChaosTokenFace
  | UseEncounterDeck ScenarioEncounterDeckKey -- The Wages of Sin
  | UseSkillInPlaceOf SkillType SkillType -- oh no, why are these similar, this let's you choose
  | UseSkillInsteadOf SkillType SkillType -- this doesn't
  | XPModifier Int
  | IfSuccessfulModifier ModifierType
  | NoInitialSwarm
  | -- UI only modifiers
    Ethereal -- from Ethereal Form
  | Explosion -- from Dyanamite Blast
  deriving stock (Show, Eq, Ord, Data)

_UpkeepResources :: Prism' ModifierType Int
_UpkeepResources = prism' UpkeepResources $ \case
  UpkeepResources n -> Just n
  _ -> Nothing

_AdditionalStartingCards :: Prism' ModifierType [Card]
_AdditionalStartingCards = prism' AdditionalStartingCards $ \case
  AdditionalStartingCards n -> Just n
  _ -> Nothing

_AlternateSuccessfullInvestigation :: Prism' ModifierType Target
_AlternateSuccessfullInvestigation = prism' AlternateSuccessfullInvestigation $ \case
  AlternateSuccessfullInvestigation n -> Just n
  _ -> Nothing

_MetaModifier :: Prism' ModifierType Value
_MetaModifier = prism' MetaModifier $ \case
  MetaModifier n -> Just n
  _ -> Nothing

_PlayableModifierContexts :: Prism' ModifierType [(CardMatcher, [ModifierType])]
_PlayableModifierContexts = prism' PlayableModifierContexts $ \case
  PlayableModifierContexts n -> Just n
  _ -> Nothing

_SearchDepth :: Prism' ModifierType Int
_SearchDepth = prism' SearchDepth $ \case
  SearchDepth n -> Just n
  _ -> Nothing

_AdditionalTargets :: Prism' ModifierType Int
_AdditionalTargets = prism' AdditionalTargets $ \case
  AdditionalTargets n -> Just n
  _ -> Nothing

_CannotEnter :: Prism' ModifierType LocationId
_CannotEnter = prism' CannotEnter $ \case
  CannotEnter n -> Just n
  _ -> Nothing

_CanCommitToSkillTestsAsIfInHand :: Prism' ModifierType Card
_CanCommitToSkillTestsAsIfInHand = prism' CanCommitToSkillTestsAsIfInHand $ \case
  CanCommitToSkillTestsAsIfInHand n -> Just n
  _ -> Nothing

data Modifier = Modifier
  { modifierSource :: Source
  , modifierType :: ModifierType
  , modifierActiveDuringSetup :: Bool
  }
  deriving stock (Show, Eq, Ord, Data)

data ActionTarget
  = FirstOneOfPerformed [Action]
  | IsAction Action
  | EnemyAction Action EnemyMatcher
  | IsAnyAction
  deriving stock (Show, Eq, Ord, Data)

instance IsLabel "draw" ActionTarget where
  fromLabel = IsAction #draw

instance IsLabel "move" ActionTarget where
  fromLabel = IsAction #move

instance IsLabel "investigate" ActionTarget where
  fromLabel = IsAction #investigate

setActiveDuringSetup :: Modifier -> Modifier
setActiveDuringSetup m = m {modifierActiveDuringSetup = True}

$(deriveJSON defaultOptions ''ActionTarget)
$( do
    deriveModifierType <- deriveJSON defaultOptions ''ModifierType
    deriveModifier <- deriveJSON (aesonOptions $ Just "modifier") ''Modifier
    pure $ deriveModifierType ++ deriveModifier
 )

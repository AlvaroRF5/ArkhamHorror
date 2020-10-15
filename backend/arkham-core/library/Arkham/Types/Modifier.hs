module Arkham.Types.Modifier
  ( Modifier(..)
  , ActionTarget(..)
  , isBlank
  )
where

import Arkham.Types.Action
import Arkham.Types.Card
import Arkham.Types.SkillType
import Arkham.Types.Token
import Arkham.Types.Trait
import ClassyPrelude
import Data.Aeson

data Modifier
  = ActionCostOf ActionTarget Int
  | ActionSkillModifier Action SkillType Int
  | AdditionalActions Int
  | BaseSkillOf SkillType Int
  | Blank
  | CanPlayTopOfDiscard (Maybe PlayerCardType, [Trait])
  | CannotBeAttackedByNonElite
  | CannotBeEnteredByNonElite
  | CannotMove
  | CannotGainResources
  | CannotHealHorror
  | CannotCancelHorror
  | DoNotDrawChaosTokensForSkillChecks
  | SpawnNonEliteAtConnectingInstead
  | CannotDiscoverClues
  | CannotInvestigate
  | CannotPlay [PlayerCardType]
  | CannotSpendClues
  | ControlledAssetsCannotReady
  | DamageDealt Int
  | HorrorDealt Int
  | DamageTaken Int
  | DiscoveredClues Int
  | DoubleNegativeModifiersOnTokens
  | EnemyEvade Int
  | EnemyFight Int
  | ForcedTokenChange Token Token
  | HealthModifier Int
  | ReduceCostOf [Trait] Int
  | ReduceCostOfCardType PlayerCardType Int
  | SanityModifier Int
  | ShroudModifier Int
  | SkillModifier SkillType Int
  | AnySkillValue Int
  | UseSkillInPlaceOf SkillType SkillType
  | XPModifier Int
  | ModifierIfSucceededBy Int Modifier
  deriving stock (Show, Eq, Generic)
  deriving anyclass (FromJSON, ToJSON, Hashable)

data ActionTarget
  = FirstOneOf [Action]
  | IsAction Action
  deriving stock (Show, Eq, Generic)
  deriving anyclass (FromJSON, ToJSON, Hashable)

isBlank :: Modifier -> Bool
isBlank Blank{} = True
isBlank _ = False

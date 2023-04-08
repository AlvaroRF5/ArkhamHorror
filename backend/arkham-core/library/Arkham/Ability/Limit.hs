module Arkham.Ability.Limit where

import Arkham.Prelude

import Arkham.Card.CardDef
import Arkham.Trait

data CanIgnoreAbilityLimit = CanIgnoreAbilityLimit | CanNotIgnoreAbilityLimit
  deriving stock Eq

data AbilityLimit
  = PerInvestigatorLimit AbilityLimitType Int
  | PlayerLimit AbilityLimitType Int
  | GroupLimit AbilityLimitType Int
  | PerCopyLimit CardDef AbilityLimitType Int
  | NoLimit
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, Hashable)

abilityLimitType :: AbilityLimit -> Maybe AbilityLimitType
abilityLimitType (PerInvestigatorLimit t _) = Just t
abilityLimitType (PlayerLimit t _) = Just t
abilityLimitType (GroupLimit t _) = Just t
abilityLimitType (PerCopyLimit _ t _) = Just t
abilityLimitType NoLimit = Nothing

abilityLimitAmount :: AbilityLimit -> Maybe Int
abilityLimitAmount (PerInvestigatorLimit _ n) = Just n
abilityLimitAmount (PlayerLimit _ n) = Just n
abilityLimitAmount (GroupLimit _ n) = Just n
abilityLimitAmount (PerCopyLimit _ _ n) = Just n
abilityLimitAmount NoLimit = Nothing

data AbilityLimitType
  = PerGame
  | PerPhase
  | PerRound
  | PerTurn
  | PerWindow
  | PerTestOrAbility
  | PerSearch Trait
  | PerDepthLevel
  | PerCampaign
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, Hashable)

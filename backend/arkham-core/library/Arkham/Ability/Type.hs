module Arkham.Ability.Type where

import Arkham.Prelude

import Arkham.Action
import Arkham.Cost
import Arkham.Matcher
import Arkham.Modifier
import Arkham.SkillType

data AbilityType
  = FastAbility Cost
  | ReactionAbility WindowMatcher Cost
  | ActionAbility (Maybe Action) Cost
  | ActionAbilityWithSkill (Maybe Action) SkillType Cost
  | ActionAbilityWithBefore (Maybe Action) (Maybe Action) Cost -- Action is first type, before is second
  | SilentForcedAbility WindowMatcher
  | ForcedAbility WindowMatcher
  | ForcedAbilityWithCost WindowMatcher Cost
  | AbilityEffect Cost
  | Objective AbilityType
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, Hashable)

abilityTypeAction :: AbilityType -> Maybe Action
abilityTypeAction = \case
  FastAbility _ -> Nothing
  ReactionAbility {} -> Nothing
  ActionAbility mAction _ -> mAction
  ActionAbilityWithSkill mAction _ _ -> mAction
  ActionAbilityWithBefore mAction _ _ -> mAction
  ForcedAbility _ -> Nothing
  SilentForcedAbility _ -> Nothing
  ForcedAbilityWithCost _ _ -> Nothing
  AbilityEffect _ -> Nothing
  Objective aType -> abilityTypeAction aType

abilityTypeCost :: AbilityType -> Cost
abilityTypeCost = \case
  FastAbility cost -> cost
  ReactionAbility _ cost -> cost
  ActionAbility _ cost -> cost
  ActionAbilityWithSkill _ _ cost -> cost
  ActionAbilityWithBefore _ _ cost -> cost
  SilentForcedAbility _ -> Free
  ForcedAbility _ -> Free
  ForcedAbilityWithCost _ cost -> cost
  AbilityEffect cost -> cost
  Objective aType -> abilityTypeCost aType

applyAbilityTypeModifiers :: AbilityType -> [ModifierType] -> AbilityType
applyAbilityTypeModifiers aType modifiers = case aType of
  FastAbility cost -> FastAbility $ applyCostModifiers cost modifiers
  ReactionAbility window cost ->
    ReactionAbility window $ applyCostModifiers cost modifiers
  ActionAbility mAction cost ->
    ActionAbility mAction $ applyCostModifiers cost modifiers
  ActionAbilityWithSkill mAction skill cost ->
    ActionAbilityWithSkill mAction skill $ applyCostModifiers cost modifiers
  ActionAbilityWithBefore mAction mBeforeAction cost ->
    ActionAbilityWithBefore mAction mBeforeAction $
      applyCostModifiers cost modifiers
  ForcedAbility window -> ForcedAbility window
  SilentForcedAbility window -> SilentForcedAbility window
  ForcedAbilityWithCost window cost ->
    ForcedAbilityWithCost window $ applyCostModifiers cost modifiers
  AbilityEffect cost -> AbilityEffect cost -- modifiers don't yet apply here
  Objective aType' -> Objective $ applyAbilityTypeModifiers aType' modifiers

applyCostModifiers :: Cost -> [ModifierType] -> Cost
applyCostModifiers = foldl' applyCostModifier

applyCostModifier :: Cost -> ModifierType -> Cost
applyCostModifier (ActionCost n) (ActionCostModifier m) =
  ActionCost (max 0 $ n + m)
applyCostModifier (Costs (x : xs)) modifier@(ActionCostModifier _) = case x of
  ActionCost _ -> Costs (applyCostModifier x modifier : xs)
  other -> other <> applyCostModifier (Costs xs) modifier
applyCostModifier (ActionCost _) (ActionCostSetToModifier m) = ActionCost m
applyCostModifier (Costs (x : xs)) modifier@(ActionCostSetToModifier _) =
  case x of
    ActionCost _ -> Costs (applyCostModifier x modifier : xs)
    other -> other <> applyCostModifier (Costs xs) modifier
applyCostModifier cost _ = cost

defaultAbilityWindow :: AbilityType -> WindowMatcher
defaultAbilityWindow = \case
  FastAbility _ -> FastPlayerWindow
  ActionAbility {} -> DuringTurn You
  ActionAbilityWithBefore {} -> DuringTurn You
  ActionAbilityWithSkill {} -> DuringTurn You
  ForcedAbility window -> window
  SilentForcedAbility window -> window
  ForcedAbilityWithCost window _ -> window
  ReactionAbility window _ -> window
  AbilityEffect _ -> AnyWindow
  Objective aType -> defaultAbilityWindow aType

isFastAbilityType :: AbilityType -> Bool
isFastAbilityType = \case
  FastAbility {} -> True
  ForcedAbility {} -> False
  SilentForcedAbility {} -> False
  ForcedAbilityWithCost {} -> False
  Objective aType -> go aType
  ReactionAbility {} -> False
  ActionAbility {} -> False
  ActionAbilityWithSkill {} -> False
  ActionAbilityWithBefore {} -> False
  AbilityEffect {} -> False

isForcedAbilityType :: AbilityType -> Bool
isForcedAbilityType = \case
  SilentForcedAbility {} -> True
  ForcedAbility {} -> True
  ForcedAbilityWithCost {} -> True
  Objective aType -> go aType
  FastAbility {} -> False
  ReactionAbility {} -> False
  ActionAbility {} -> False
  ActionAbilityWithSkill {} -> False
  ActionAbilityWithBefore {} -> False
  AbilityEffect {} -> False

isSilentForcedAbilityType :: AbilityType -> Bool
isSilentForcedAbilityType = \case
  SilentForcedAbility {} -> True
  ForcedAbility {} -> False
  ForcedAbilityWithCost {} -> False
  Objective aType -> go aType
  FastAbility {} -> False
  ReactionAbility {} -> False
  ActionAbility {} -> False
  ActionAbilityWithSkill {} -> False
  ActionAbilityWithBefore {} -> False
  AbilityEffect {} -> False

defaultAbilityLimit :: AbilityType -> AbilityLimit
defaultAbilityLimit = \case
  ForcedAbility _ -> GroupLimit PerWindow 1
  SilentForcedAbility _ -> GroupLimit PerWindow 1
  ForcedAbilityWithCost _ _ -> GroupLimit PerWindow 1
  ReactionAbility _ _ -> PlayerLimit PerWindow 1
  FastAbility _ -> NoLimit
  ActionAbility _ _ -> NoLimit
  ActionAbilityWithBefore {} -> NoLimit
  ActionAbilityWithSkill {} -> NoLimit
  AbilityEffect _ -> NoLimit
  Objective aType -> defaultAbilityLimit aType

module Arkham.Action where

import Arkham.Prelude
import GHC.OverloadedLabels

data ActionType
  = EnemyActionType
  | LocationActionType
  | AssetActionType
  | TreacheryActionType
  | ActActionType
  | AgendaActionType
  | InvestigatorActionType
  deriving stock (Bounded, Enum, Show)

newtype TakenAction = TakenAction {unTakenAction :: Action}
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)

data Action
  = Ability
  | Draw
  | Engage
  | Evade
  | Fight
  | Investigate
  | Move
  | Parley
  | Play
  | Resign
  | Resource
  | Explore
  | Circle
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic, Data)
  deriving anyclass (ToJSON, FromJSON, Hashable)

instance IsLabel "investigate" Action where
  fromLabel = Investigate

instance IsLabel "move" Action where
  fromLabel = Move

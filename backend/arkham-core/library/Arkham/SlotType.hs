module Arkham.SlotType where

import Arkham.Prelude

data SlotType
  = HandSlot
  | BodySlot
  | AllySlot
  | AccessorySlot
  | ArcaneSlot
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON, Hashable, ToJSONKey, FromJSONKey)

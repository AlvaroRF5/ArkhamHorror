module Arkham.GameValue
  ( GameValue(..)
  , fromGameValue
  ) where

import Arkham.Prelude

data GameValue
  = Static Int
  | PerPlayer Int
  | StaticWithPerPlayer Int Int
  | ByPlayerCount Int Int Int Int
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)

fromGameValue :: GameValue -> Int -> Int
fromGameValue (Static n) _ = n
fromGameValue (PerPlayer n) pc = n * pc
fromGameValue (StaticWithPerPlayer n m) pc = n + (m * pc)
fromGameValue (ByPlayerCount n1 n2 n3 n4) pc = case pc of
  1 -> n1
  2 -> n2
  3 -> n3
  4 -> n4
  _ -> error "Unhandled by player count value"

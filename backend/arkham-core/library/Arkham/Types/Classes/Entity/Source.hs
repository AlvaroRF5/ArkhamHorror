module Arkham.Types.Classes.Entity.Source where

import Arkham.Prelude hiding (to)

import Arkham.Types.Source

class SourceEntity a where
  toSource :: a -> Source
  isSource :: a -> Source -> Bool
  isSource = (==) . toSource

instance SourceEntity Source where
  toSource = id
  isSource = (==)

instance SourceEntity a => SourceEntity (a `With` b) where
  toSource (a `With` _) = toSource a
  isSource (a `With` _) = isSource a

module Arkham.Classes.Entity (
  module Arkham.Classes.Entity,
  module X,
) where

import Arkham.Prelude hiding (to)

import Arkham.Classes.Entity.Source as X
import Arkham.Target
import Arkham.Token

class Entity a where
  type EntityId a
  type EntityAttrs a
  toId :: a -> EntityId a
  toAttrs :: a -> EntityAttrs a
  overAttrs :: (EntityAttrs a -> EntityAttrs a) -> a -> a

patchEntity :: Entity a => a -> EntityAttrs a -> a
patchEntity a attrs = overAttrs (const attrs) a

class TargetEntity a where
  toTarget :: a -> Target
  isTarget :: a -> Target -> Bool
  isTarget = (==) . toTarget

instance TargetEntity Target where
  toTarget = id
  isTarget = (==)

instance Entity a => Entity (a `With` b) where
  type EntityId (a `With` b) = EntityId a
  type EntityAttrs (a `With` b) = EntityAttrs a
  toId (a `With` _) = toId a
  toAttrs (a `With` _) = toAttrs a
  overAttrs f (a `With` b) = With (overAttrs f a) b

instance TargetEntity a => TargetEntity (a `With` b) where
  toTarget (a `With` _) = toTarget a
  isTarget (a `With` _) = isTarget a

insertEntity ::
  (Entity v, EntityId v ~ k, Hashable k) =>
  v ->
  HashMap k v ->
  HashMap k v
insertEntity a = insertMap (toId a) a

instance TargetEntity Token where
  toTarget = TokenTarget
  isTarget t (TokenTarget t') = t == t'
  isTarget _ _ = False

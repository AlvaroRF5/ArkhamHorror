module Arkham.Effect.Attrs where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Card
import Arkham.Classes.Entity
import Arkham.Classes.HasAbilities
import Arkham.Classes.HasModifiersFor
import Arkham.Classes.RunMessage.Internal
import Arkham.Effect.Window
import Arkham.Id
import Arkham.EffectMetadata
import Arkham.Json
import Arkham.Message
import Arkham.Projection
import Arkham.Source
import Arkham.Target
import Arkham.Trait
import Arkham.Window ( Window )

class (Typeable a, ToJSON a, FromJSON a, Eq a, Show a, HasAbilities a, HasModifiersFor a, RunMessage a, Entity a, EntityId a ~ EffectId, EntityAttrs a ~ EffectAttrs) => IsEffect a

data instance Field EffectAttrs :: Type -> Type where
  EffectAbilities :: Field EffectAttrs [Ability]

data EffectAttrs = EffectAttrs
  { effectId :: EffectId
  , effectCardCode :: Maybe CardCode
  , effectTarget :: Target
  , effectSource :: Source
  , effectTraits :: HashSet Trait
  , effectMetadata :: Maybe (EffectMetadata Window Message)
  , effectWindow :: Maybe EffectWindow
  }
  deriving stock (Show, Eq, Generic)

type EffectArgs
  = (EffectId, Maybe (EffectMetadata Window Message), Source, Target)

baseAttrs
  :: CardCode
  -> EffectId
  -> Maybe (EffectMetadata Window Message)
  -> Source
  -> Target
  -> EffectAttrs
baseAttrs cardCode eid meffectMetadata source target = EffectAttrs
  { effectId = eid
  , effectSource = source
  , effectTarget = target
  , effectCardCode = Just cardCode
  , effectMetadata = meffectMetadata
  , effectTraits = mempty
  , effectWindow = Nothing
  }

instance ToJSON EffectAttrs where
  toJSON = genericToJSON $ aesonOptions $ Just "effect"
  toEncoding = genericToEncoding $ aesonOptions $ Just "effect"

instance FromJSON EffectAttrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "effect"

instance HasAbilities EffectAttrs

isEndOfWindow :: EffectAttrs -> EffectWindow -> Bool
isEndOfWindow EffectAttrs { effectWindow } effectWindow' = effectWindow'
  `elem` toEffectWindowList effectWindow
 where
  toEffectWindowList Nothing = []
  toEffectWindowList (Just (FirstEffectWindow xs)) = xs
  toEffectWindowList (Just x) = [x]

instance Entity EffectAttrs where
  type EntityId EffectAttrs = EffectId
  type EntityAttrs EffectAttrs = EffectAttrs
  toId = effectId
  toAttrs = id

instance TargetEntity EffectAttrs where
  toTarget = EffectTarget . toId
  isTarget EffectAttrs { effectId } (EffectTarget eid) = effectId == eid
  isTarget _ _ = False

instance SourceEntity EffectAttrs where
  toSource = EffectSource . toId
  isSource EffectAttrs { effectId } (EffectSource eid) = effectId == eid
  isSource _ _ = False

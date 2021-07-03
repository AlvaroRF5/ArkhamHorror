module Arkham.Types.Effect.Attrs
  ( module Arkham.Types.Effect.Attrs
  ) where

import Arkham.Prelude

import Arkham.Json
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Effect.Window
import Arkham.Types.EffectId
import Arkham.Types.EffectMetadata
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Trait

data EffectAttrs = EffectAttrs
  { effectId :: EffectId
  , effectCardCode :: Maybe CardCode
  , effectTarget :: Target
  , effectSource :: Source
  , effectTraits :: HashSet Trait
  , effectMetadata :: Maybe (EffectMetadata Message)
  , effectWindow :: Maybe EffectWindow
  }
  deriving stock (Show, Eq, Generic)

type EffectArgs = (EffectId, Maybe (EffectMetadata Message), Source, Target)

baseAttrs
  :: CardCode
  -> EffectId
  -> Maybe (EffectMetadata Message)
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

instance HasActions env EffectAttrs where
  getActions _ _ _ = pure []

instance HasQueue env => RunMessage env EffectAttrs where
  runMessage msg a@EffectAttrs {..} = case msg of
    EndSetup | EffectSetupWindow `elem` effectWindow ->
      a <$ unshiftMessage (DisableEffect effectId)
    EndPhase | EffectPhaseWindow `elem` effectWindow ->
      a <$ unshiftMessage (DisableEffect effectId)
    EndRound | EffectRoundWindow `elem` effectWindow ->
      a <$ unshiftMessage (DisableEffect effectId)
    SkillTestEnds _ | EffectSkillTestWindow `elem` effectWindow ->
      a <$ unshiftMessage (DisableEffect effectId)
    CancelSkillEffects -> case effectSource of
      (SkillSource _) -> a <$ unshiftMessage (DisableEffect effectId)
      _ -> pure a
    _ -> pure a

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

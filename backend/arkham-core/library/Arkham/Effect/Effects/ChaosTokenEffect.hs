module Arkham.Effect.Effects.ChaosTokenEffect (
  ChaosTokenEffect (..),
  chaosTokenEffect,
  chaosTokenEffect',
) where

import Arkham.Prelude

import Arkham.ChaosToken
import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Id
import Arkham.Message
import Arkham.Window (Window)

newtype ChaosTokenEffect = ChaosTokenEffect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

chaosTokenEffect :: EffectArgs -> ChaosTokenEffect
chaosTokenEffect = ChaosTokenEffect . uncurry4 (baseAttrs "ctokef")

chaosTokenEffect'
  :: EffectId -> EffectMetadata Window Message -> Source -> ChaosToken -> ChaosTokenEffect
chaosTokenEffect' eid metadata source chaosToken =
  ChaosTokenEffect $
    EffectAttrs
      { effectId = eid
      , effectSource = source
      , effectTarget = ChaosTokenTarget chaosToken
      , effectCardCode = "ctokef"
      , effectMetadata = Just metadata
      , effectTraits = mempty
      , effectWindow = Nothing
      , effectFinished = False
      }

instance HasModifiersFor ChaosTokenEffect where
  getModifiersFor target (ChaosTokenEffect attrs) | target == effectTarget attrs =
    case effectMetadata attrs of
      Just (EffectModifiers modifiers) -> pure modifiers
      Just (FailedByEffectModifiers modifiers) -> pure modifiers
      _ -> pure []
  getModifiersFor _ _ = pure []

instance RunMessage ChaosTokenEffect where
  runMessage msg e@(ChaosTokenEffect attrs@EffectAttrs {..}) = case msg of
    ResetChaosTokens _ -> e <$ push (DisableEffect effectId)
    ReturnChaosTokens chaosTokens -> do
      when
        (effectTarget `elem` map ChaosTokenTarget chaosTokens)
        (push $ DisableEffect effectId)
      pure e
    _ -> ChaosTokenEffect <$> runMessage msg attrs

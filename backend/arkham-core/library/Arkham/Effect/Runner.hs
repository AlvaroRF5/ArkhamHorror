module Arkham.Effect.Runner (module Arkham.Effect.Runner, module X) where

import Arkham.Prelude

import Arkham.Effect.Attrs as X
import Arkham.Effect.Window as X
import Arkham.EffectMetadata as X

import Arkham.Classes.RunMessage
import Arkham.Source
import Arkham.Message

instance RunMessage EffectAttrs where
  runMessage msg a@EffectAttrs {..} = case msg of
    EndSetup | isEndOfWindow a EffectSetupWindow ->
      a <$ push (DisableEffect effectId)
    EndPhase | isEndOfWindow a EffectPhaseWindow ->
      a <$ push (DisableEffect effectId)
    EndTurn _ | isEndOfWindow a EffectTurnWindow ->
      a <$ push (DisableEffect effectId)
    EndRound | isEndOfWindow a EffectRoundWindow ->
      a <$ push (DisableEffect effectId)
    SkillTestEnds _ | isEndOfWindow a EffectSkillTestWindow ->
      a <$ push (DisableEffect effectId)
    CancelSkillEffects -> case effectSource of
      (SkillSource _) -> a <$ push (DisableEffect effectId)
      _ -> pure a
    _ -> pure a


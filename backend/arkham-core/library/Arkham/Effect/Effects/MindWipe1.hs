module Arkham.Effect.Effects.MindWipe1
  ( mindWipe1
  , MindWipe1(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Effect.Attrs
import Arkham.Effect.Helpers
import Arkham.Message
import Arkham.Modifier

newtype MindWipe1 = MindWipe1 EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

mindWipe1 :: EffectArgs -> MindWipe1
mindWipe1 = MindWipe1 . uncurry4 (baseAttrs "01068")

instance HasModifiersFor env MindWipe1 where
  getModifiersFor _ target (MindWipe1 a@EffectAttrs {..})
    | target == effectTarget = pure [toModifier a Blank]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env MindWipe1 where
  runMessage msg e@(MindWipe1 attrs) = case msg of
    EndPhase -> e <$ push (DisableEffect $ effectId attrs)
    _ -> MindWipe1 <$> runMessage msg attrs

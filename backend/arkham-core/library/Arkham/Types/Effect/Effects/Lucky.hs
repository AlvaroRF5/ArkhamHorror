module Arkham.Types.Effect.Effects.Lucky
  ( lucky
  , Lucky(..)
  )
where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.Effect.Attrs
import Arkham.Types.Effect.Helpers
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Target

newtype Lucky = Lucky EffectAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

lucky :: EffectArgs -> Lucky
lucky = Lucky . uncurry4 (baseAttrs "01080")

instance HasModifiersFor env Lucky where
  getModifiersFor _ target (Lucky a@EffectAttrs {..}) | target == effectTarget =
    pure [toModifier a $ AnySkillValue 2]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env Lucky where
  runMessage msg e@(Lucky attrs) = case msg of
    CreatedEffect eid _ _ (InvestigatorTarget _) | eid == effectId attrs ->
      e <$ push RerunSkillTest
    SkillTestEnds _ -> e <$ push (DisableEffect $ effectId attrs)
    _ -> Lucky <$> runMessage msg attrs

module Arkham.Types.Effect.Effects.CursedShores
  ( cursedShores
  , CursedShores(..)
  )
where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.Effect.Attrs
import Arkham.Types.Effect.Helpers
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Source
import Arkham.Types.Target

newtype CursedShores = CursedShores EffectAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cursedShores :: EffectArgs -> CursedShores
cursedShores = CursedShores . uncurry4 (baseAttrs "81007")

instance HasModifiersFor env CursedShores where
  getModifiersFor SkillTestSource{} target (CursedShores a@EffectAttrs {..})
    | target == effectTarget = pure [toModifier a (AnySkillValue 2)]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env CursedShores where
  runMessage msg e@(CursedShores attrs) = case msg of
    SkillTestEnds _ -> e <$ push (DisableEffect $ effectId attrs)
    EndTurn iid | InvestigatorTarget iid == effectTarget attrs ->
      e <$ push (DisableEffect $ effectId attrs)
    _ -> CursedShores <$> runMessage msg attrs

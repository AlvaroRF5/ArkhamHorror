module Arkham.Effect.Effects.Deduction2
  ( deduction2
  , Deduction2(..)
  ) where

import Arkham.Prelude

import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.Effect.Attrs
import Arkham.EffectMetadata
import Arkham.Message
import Arkham.Target

newtype Deduction2 = Deduction2 EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor m)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

deduction2 :: EffectArgs -> Deduction2
deduction2 = Deduction2 . uncurry4 (baseAttrs "02150")

instance RunMessage Deduction2 where
  runMessage msg e@(Deduction2 attrs@EffectAttrs {..}) = case msg of
    Successful (Action.Investigate, _) iid _ (LocationTarget lid) _ ->
      case effectMetadata of
        Just (EffectMetaTarget (LocationTarget lid')) | lid == lid' ->
          e <$ push
            (InvestigatorDiscoverClues iid lid 1 (Just Action.Investigate))
        _ -> pure e
    SkillTestEnds _ -> e <$ push (DisableEffect effectId)
    _ -> Deduction2 <$> runMessage msg attrs

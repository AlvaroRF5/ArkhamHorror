module Arkham.Effect.Effects.Shrivelling
  ( shrivelling
  , Shrivelling(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Message
import Arkham.Target
import Arkham.Token
import Arkham.Window (Window)
import Arkham.Window qualified as Window

newtype Shrivelling = Shrivelling EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

shrivelling :: EffectArgs -> Shrivelling
shrivelling = Shrivelling . uncurry4 (baseAttrs "01060")

intFromMetadata :: EffectMetadata Window a -> Int
intFromMetadata = \case
  EffectInt n -> n
  _ -> 0

instance RunMessage Shrivelling where
  runMessage msg e@(Shrivelling attrs@EffectAttrs {..}) = case msg of
    RevealToken _ iid token | InvestigatorTarget iid == effectTarget -> do
      let damage = maybe 1 intFromMetadata effectMetadata
      when
        (tokenFace token `elem` [Skull, Cultist, Tablet, ElderThing, AutoFail])
        (push $ If (Window.RevealToken iid token)
          [ InvestigatorAssignDamage iid effectSource DamageAny 0 damage
          , DisableEffect effectId
          ]
        )
      pure e
    SkillTestEnds _ _ -> e <$ push (DisableEffect effectId)
    _ -> Shrivelling <$> runMessage msg attrs

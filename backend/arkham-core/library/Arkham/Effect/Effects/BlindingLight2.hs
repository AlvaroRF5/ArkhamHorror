module Arkham.Effect.Effects.BlindingLight2
  ( blindingLight2
  , BlindingLight2(..)
  ) where

import Arkham.Prelude

import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Effect.Runner
import Arkham.Message
import Arkham.ChaosToken
import Arkham.Window qualified as Window

newtype BlindingLight2 = BlindingLight2 EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

blindingLight2 :: EffectArgs -> BlindingLight2
blindingLight2 = BlindingLight2 . uncurry4 (baseAttrs "01069")

instance RunMessage BlindingLight2 where
  runMessage msg e@(BlindingLight2 attrs@EffectAttrs {..}) = case msg of
    RevealChaosToken _ iid token | InvestigatorTarget iid == effectTarget ->
      e <$ when
        (chaosTokenFace token `elem` [Skull, Cultist, Tablet, ElderThing, AutoFail])
        (pushAll
          [ If
            (Window.RevealChaosTokenEffect iid token effectId)
            [ LoseActions iid (toSource attrs) 1
            , InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 1
            ]
          , DisableEffect effectId
          ]
        )
    PassedSkillTest iid (Just Action.Evade) _ (SkillTestInitiatorTarget (EnemyTarget eid)) _ _
      | SkillTestTarget == effectTarget
      -> e <$ pushAll
        [ EnemyDamage eid $ nonAttack (InvestigatorSource iid) 2
        , DisableEffect effectId
        ]
    SkillTestEnds _ _ -> e <$ push (DisableEffect effectId)
    _ -> BlindingLight2 <$> runMessage msg attrs

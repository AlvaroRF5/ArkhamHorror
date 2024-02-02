module Arkham.Event.Cards.BlindingLight where

import Arkham.Prelude

import Arkham.Action qualified as Action
import Arkham.ChaosToken
import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Event.Cards qualified as Cards (blindingLight)
import Arkham.Event.Runner
import Arkham.Window qualified as Window

newtype BlindingLight = BlindingLight EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks, NFData)

blindingLight :: EventCard BlindingLight
blindingLight = event BlindingLight Cards.blindingLight

instance RunMessage BlindingLight where
  runMessage msg e@(BlindingLight attrs) = case msg of
    PlayThisEvent iid eid | attrs `is` eid -> do
      pushAll
        [ createCardEffect Cards.blindingLight Nothing attrs iid
        , createCardEffect Cards.blindingLight Nothing attrs SkillTestTarget
        , chooseEvadeEnemy iid eid #willpower
        ]
      pure e
    _ -> BlindingLight <$> runMessage msg attrs

newtype BlindingLightEffect = BlindingLightEffect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks, NFData)

blindingLightEffect :: EffectArgs -> BlindingLightEffect
blindingLightEffect = cardEffect BlindingLightEffect Cards.blindingLight

instance RunMessage BlindingLightEffect where
  runMessage msg e@(BlindingLightEffect attrs) = case msg of
    RevealChaosToken _ iid token | InvestigatorTarget iid == attrs.target -> do
      when (chaosTokenFace token `elem` [Skull, Cultist, Tablet, ElderThing, AutoFail])
        $ pushAll
          [ If (Window.RevealChaosTokenEffect iid token (toId attrs)) [LoseActions iid (toSource attrs) 1]
          , disable attrs
          ]
      pure e
    PassedSkillTest iid (Just Action.Evade) _ (Initiator (EnemyTarget eid)) _ _ | SkillTestTarget == attrs.target -> do
      pushAll [nonAttackEnemyDamage iid 1 eid, disable attrs]
      pure e
    SkillTestEnds _ _ -> e <$ push (disable attrs)
    _ -> BlindingLightEffect <$> runMessage msg attrs

module Arkham.Event.Cards.ExposeWeakness1 (
  exposeWeakness1,
  ExposeWeakness1 (..),
) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.EffectMetadata
import Arkham.Enemy.Types (Field (..))
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Matcher
import Arkham.SkillType

newtype ExposeWeakness1 = ExposeWeakness1 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks)

exposeWeakness1 :: EventCard ExposeWeakness1
exposeWeakness1 = event ExposeWeakness1 Cards.exposeWeakness1

instance RunMessage ExposeWeakness1 where
  runMessage msg e@(ExposeWeakness1 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      enemies <-
        selectWithField
          EnemyFight
          (EnemyAt $ locationWithInvestigator iid)
          <&> mapMaybe (\(x, y) -> (x,) <$> y)
      player <- getPlayer iid
      push
        $ chooseOne
          player
          [ targetLabel
            enemy
            [ beginSkillTest
                iid
                (toSource attrs)
                (EnemyTarget enemy)
                SkillIntellect
                enemyFight
            ]
          | (enemy, enemyFight) <- enemies
          ]
      pure e
    PassedSkillTest _ _ source SkillTestInitiatorTarget {} _ n
      | isSource attrs source -> do
          mtarget <- getSkillTestTarget
          case mtarget of
            Just (EnemyTarget enemyId) ->
              e
                <$ pushAll
                  [ CreateEffect
                      "02228"
                      (Just $ EffectInt n)
                      source
                      (EnemyTarget enemyId)
                  ]
            _ -> error "had to have an enemy"
    _ -> ExposeWeakness1 <$> runMessage msg attrs

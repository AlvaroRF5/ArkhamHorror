module Arkham.Event.Cards.ExposeWeakness1
  ( exposeWeakness1
  , ExposeWeakness1(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Classes
import Arkham.EffectMetadata
import Arkham.Enemy.Attrs ( Field (..) )
import Arkham.Event.Attrs
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.SkillTest
import Arkham.SkillType
import Arkham.Target

newtype ExposeWeakness1 = ExposeWeakness1 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

exposeWeakness1 :: EventCard ExposeWeakness1
exposeWeakness1 = event ExposeWeakness1 Cards.exposeWeakness1

instance RunMessage ExposeWeakness1 where
  runMessage msg e@(ExposeWeakness1 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      enemyIds <- selectList $ EnemyAt $ LocationWithInvestigator $ InvestigatorWithId iid
      enemyIdsWithFight <- traverse
        (traverseToSnd (field EnemyFight))
        enemyIds
      e <$ push
        (chooseOne
          iid
          [ TargetLabel
              (EnemyTarget enemyId)
              [ BeginSkillTest
                  iid
                  (toSource attrs)
                  (EnemyTarget enemyId)
                  Nothing
                  SkillIntellect
                  enemyFight
              ]
          | (enemyId, enemyFight) <- enemyIdsWithFight
          ]
        )
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source -> do
        mtarget <- getSkillTestTarget
        case mtarget of
          Just (EnemyTarget enemyId) -> e <$ pushAll
            [ CreateEffect
              "02228"
              (Just $ EffectInt n)
              source
              (EnemyTarget enemyId)
            , Discard $ toTarget attrs
            ]
          _ -> error "had to have an enemy"
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> e <$ push (Discard $ toTarget attrs)
    _ -> ExposeWeakness1 <$> runMessage msg attrs

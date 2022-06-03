module Arkham.Event.Cards.HypnoticGaze
  ( hypnoticGaze
  , HypnoticGaze(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Event.Attrs
import Arkham.Enemy.Attrs
import Arkham.Id
import Arkham.Message
import Arkham.Query
import Arkham.RequestedTokenStrategy
import Arkham.Token

newtype HypnoticGaze = HypnoticGaze (EventAttrs `With` Maybe EnemyId)
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

hypnoticGaze :: EventCard HypnoticGaze
hypnoticGaze = event (HypnoticGaze . (`with` Nothing)) Cards.hypnoticGaze

dropUntilAttack :: [Message] -> [Message]
dropUntilAttack = dropWhile (notElem AttackMessage . messageType)

instance HasCount HealthDamageCount env EnemyId => RunMessage HypnoticGaze where
  runMessage msg e@(HypnoticGaze (attrs `With` mEnemyId)) = case msg of
    InvestigatorPlayEvent iid eventId _ _ _ | eventId == toId attrs -> do
      enemyId <- withQueue $ \queue ->
        let PerformEnemyAttack _ eid _ _ : queue' = dropUntilAttack queue
        in (queue', eid)
      push (RequestTokens (toSource attrs) (Just iid) 1 SetAside)
      pure $ HypnoticGaze (attrs `with` Just enemyId)
    RequestedTokens source (Just iid) faces | isSource attrs source -> do
      let
        enemyId = fromMaybe (error "missing enemy id") mEnemyId
        shouldDamageEnemy = any
          ((`elem` [Skull, Cultist, Tablet, ElderThing, AutoFail]) . tokenFace)
          faces
      if shouldDamageEnemy
        then do
          healthDamage' <- field EnemyHealthDamage enemyId
          e <$ pushAll
            [ EnemyDamage
              enemyId
              iid
              (toSource attrs)
              NonAttackDamageEffect
              healthDamage'
            , Discard $ toTarget attrs
            ]
        else e <$ push (Discard $ toTarget attrs)
    _ -> HypnoticGaze . (`with` mEnemyId) <$> runMessage msg attrs

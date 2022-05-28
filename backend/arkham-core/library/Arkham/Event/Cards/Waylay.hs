module Arkham.Event.Cards.Waylay
  ( waylay
  , Waylay(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Enemy.Attrs ( Field (..) )
import Arkham.Event.Attrs
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.SkillType
import Arkham.Target

newtype Waylay = Waylay EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

waylay :: EventCard Waylay
waylay = event Waylay Cards.waylay

instance EventRunner env => RunMessage env Waylay where
  runMessage msg e@(Waylay attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      enemies <-
        selectList
        $ NonEliteEnemy
        <> EnemyAt (LocationWithInvestigator $ InvestigatorWithId iid)
        <> ExhaustedEnemy
      enemiesWithEvade <- traverse (traverseToSnd (field EnemyEvade)) enemies
      pushAll
        [ chooseOne
          iid
          [ targetLabel
              enemy
              [ BeginSkillTest
                  iid
                  (toSource attrs)
                  (EnemyTarget enemy)
                  Nothing
                  SkillAgility
                  evade
              ]
          | (enemy, evade) <- enemiesWithEvade
          ]
        , Discard (toTarget attrs)
        ]
      pure e
    PassedSkillTest iid _ (isSource attrs -> True) (SkillTestInitiatorTarget (EnemyTarget eid)) _ _
      -> e <$ push (DefeatEnemy eid iid $ toSource attrs)
    _ -> Waylay <$> runMessage msg attrs

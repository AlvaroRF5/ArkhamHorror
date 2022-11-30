module Arkham.Event.Cards.SneakAttack2
  ( sneakAttack2
  , SneakAttack2(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Helpers.Investigator
import Arkham.Matcher hiding ( NonAttackDamageEffect )
import Arkham.Message

newtype SneakAttack2 = SneakAttack2 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sneakAttack2 :: EventCard SneakAttack2
sneakAttack2 = event SneakAttack2 Cards.sneakAttack2

instance RunMessage SneakAttack2 where
  runMessage msg e@(SneakAttack2 attrs) = case msg of
    InvestigatorPlayEvent you eid _ _ _ | eid == toId attrs -> do
      enemies <- selectList $ EnemyNotEngagedWithYou <> enemiesColocatedWith you
      pushAll
        $ [ EnemyDamage enemy (toSource attrs) NonAttackDamageEffect 2
          | enemy <- enemies
          ]
        <> [Discard $ toTarget attrs]
      pure e
    _ -> SneakAttack2 <$> runMessage msg attrs

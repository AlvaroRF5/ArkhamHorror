module Arkham.Event.Cards.ManoAMano1
  ( manoAMano1
  , ManoAMano1(..)
  )
where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Event.Runner
import Arkham.Event.Runner
import Arkham.Matcher hiding (NonAttackDamageEffect)
import Arkham.Message

newtype ManoAMano1 = ManoAMano1 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

manoAMano1 :: EventCard ManoAMano1
manoAMano1 =
  event ManoAMano1 Cards.manoAMano1

instance RunMessage ManoAMano1 where
  runMessage msg e@(ManoAMano1 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      enemies <- selectList $ EnemyIsEngagedWith $ InvestigatorWithId iid
      pushAll
        [ chooseOrRunOne iid
          [ EnemyDamage enemy iid (toSource attrs) NonAttackDamageEffect 1
          | enemy <- enemies
          ]
        , Discard (toTarget attrs)
        ]
      pure e
    _ -> ManoAMano1 <$> runMessage msg attrs

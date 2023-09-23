module Arkham.Event.Cards.Taunt2 (
  taunt2,
  Taunt2 (..),
) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Helpers.Investigator
import Arkham.Message

newtype Taunt2 = Taunt2 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

taunt2 :: EventCard Taunt2
taunt2 = event Taunt2 Cards.taunt2

instance RunMessage Taunt2 where
  runMessage msg e@(Taunt2 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> do
      enemyIds <- selectList $ enemiesColocatedWith iid
      enemies <- forToSnd enemyIds $ \_ -> drawCards iid attrs 1
      push
        $ chooseSome
          iid
          "Done engaging enemies"
          [ targetLabel enemyId [EngageEnemy iid enemyId False, drawing]
          | (enemyId, drawing) <- enemies
          ]
      pure e
    _ -> Taunt2 <$> runMessage msg attrs

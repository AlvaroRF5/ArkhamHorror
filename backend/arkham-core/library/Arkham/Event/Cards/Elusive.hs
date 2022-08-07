module Arkham.Event.Cards.Elusive where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Classes
import Arkham.Event.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype Elusive = Elusive EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

elusive :: EventCard Elusive
elusive = event Elusive Cards.elusive

instance RunMessage Elusive where
  runMessage msg e@(Elusive attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> do
      enemyIds <- selectList $ EnemyIsEngagedWith $ InvestigatorWithId iid
      targets <- selectList $ EmptyLocation <> RevealedLocation
      e <$ pushAll
        ([ DisengageEnemy iid enemyId | enemyId <- enemyIds ]
        <> [ chooseOrRunOne
               iid
               [ MoveTo (toSource attrs) iid lid | lid <- targets ]
           | notNull targets
           ]
        <> map EnemyCheckEngagement enemyIds
        <> [Discard (EventTarget eventId)]
        )
    _ -> Elusive <$> runMessage msg attrs

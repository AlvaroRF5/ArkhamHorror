module Arkham.Event.Cards.CheatDeath5
  ( cheatDeath5
  , CheatDeath5(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype CheatDeath5 = CheatDeath5 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cheatDeath5 :: EventCard CheatDeath5
cheatDeath5 = event CheatDeath5 Cards.cheatDeath5

instance RunMessage CheatDeath5 where
  runMessage msg e@(CheatDeath5 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      enemies <- selectList $ EnemyIsEngagedWith $ InvestigatorWithId iid
      treacheries <- selectList $ TreacheryInThreatAreaOf $ InvestigatorWithId
        iid
      locations <- selectList $ RevealedLocation <> LocationWithoutEnemies <> NotLocation (locationWithInvestigator iid)
      yourTurn <- member iid <$> select TurnInvestigator

      replaceMessageMatching
        (\case
          InvestigatorWhenDefeated _ iid' -> iid == iid'
          _ -> False
        )
        (\case
          InvestigatorWhenDefeated source' _ -> [CheckDefeated source']
          _ -> error "invalid match"
        )

      pushAll
        $ map (DisengageEnemy iid) enemies
        <> map (Discard . TreacheryTarget) treacheries
        <> [ HealHorror (InvestigatorTarget iid) (toSource attrs) 2
           , HealDamage (InvestigatorTarget iid) (toSource attrs) 2
           ]
        <> [ chooseOrRunOne iid $ map
               (\lid -> targetLabel lid [MoveTo (toSource attrs) iid lid])
               locations
           | notNull locations
           ]
        <> [ ChooseEndTurn iid | yourTurn ]
        <> [RemoveFromGame $ toTarget attrs]
      pure e
    _ -> CheatDeath5 <$> runMessage msg attrs

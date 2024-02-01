module Arkham.Event.Cards.AlterFate1 (
  alterFate1,
  AlterFate1 (..),
) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Matcher

newtype AlterFate1 = AlterFate1 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks)

alterFate1 :: EventCard AlterFate1
alterFate1 = event AlterFate1 Cards.alterFate1

instance RunMessage AlterFate1 where
  runMessage msg e@(AlterFate1 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      treacheries <- selectList $ NotTreachery (TreacheryOnEnemy EliteEnemy) <> TreacheryIsNonWeakness
      player <- getPlayer iid
      pushAll
        [ chooseOne
            player
            [ targetLabel treachery [toDiscardBy iid attrs treachery]
            | treachery <- treacheries
            ]
        ]
      pure e
    _ -> AlterFate1 <$> runMessage msg attrs

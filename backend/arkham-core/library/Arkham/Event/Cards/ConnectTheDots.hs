module Arkham.Event.Cards.ConnectTheDots (
  connectTheDots,
  ConnectTheDots (..),
) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Helpers.Investigator
import Arkham.Matcher
import Arkham.Message

newtype ConnectTheDots = ConnectTheDots EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

connectTheDots :: EventCard ConnectTheDots
connectTheDots = event ConnectTheDots Cards.connectTheDots

instance RunMessage ConnectTheDots where
  runMessage msg e@(ConnectTheDots attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      lid <- getJustLocation iid
      locations <-
        selectList $
          LocationWithLowerShroudThan (LocationWithId lid)
            <> LocationWithDiscoverableCluesBy (InvestigatorWithId iid)
      push $
        chooseOrRunOne
          iid
          [ targetLabel location [DiscoverCluesAtLocation iid location (toSource attrs) 2 Nothing]
          | location <- locations
          ]
      pure e
    _ -> ConnectTheDots <$> runMessage msg attrs

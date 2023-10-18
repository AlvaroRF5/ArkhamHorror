module Arkham.Event.Cards.NoStoneUnturned (
  noStoneUnturned,
  NoStoneUnturned (..),
) where

import Arkham.Prelude

import Arkham.Capability
import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Matcher

newtype NoStoneUnturned = NoStoneUnturned EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

noStoneUnturned :: EventCard NoStoneUnturned
noStoneUnturned = event NoStoneUnturned Cards.noStoneUnturned

instance RunMessage NoStoneUnturned where
  runMessage msg e@(NoStoneUnturned attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      iids <-
        selectList
          $ affectsOthers
          $ InvestigatorAt YourLocation
          <> can.manipulate.deck

      player <- getPlayer iid
      pushAll
        [ chooseOne
            player
            [ targetLabel
              iid'
              [ search
                  iid'
                  (toSource attrs)
                  (InvestigatorTarget iid')
                  [fromTopOfDeck 6]
                  AnyCard
                  (DrawFound iid' 1)
              ]
            | iid' <- iids
            ]
        ]
      pure e
    _ -> NoStoneUnturned <$> runMessage msg attrs

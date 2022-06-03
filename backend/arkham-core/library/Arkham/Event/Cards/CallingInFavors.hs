module Arkham.Event.Cards.CallingInFavors
  ( callingInFavors
  , CallingInFavors(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Card
import Arkham.Card.Cost
import Arkham.Classes
import Arkham.EffectMetadata
import Arkham.Event.Attrs
import Arkham.Event.Runner
import Arkham.Matcher hiding (PlayCard)
import Arkham.Message
import Arkham.Target

newtype CallingInFavors = CallingInFavors EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

callingInFavors :: EventCard CallingInFavors
callingInFavors = event CallingInFavors Cards.callingInFavors

instance EventRunner env => RunMessage CallingInFavors where
  runMessage msg e@(CallingInFavors attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      allies <- selectList $ AllyAsset <> AssetControlledBy
        (InvestigatorWithId iid)
      targetsWithCosts <- for
        allies
        \ally -> do
          cardDef <- getCardDef ally
          pure (AssetTarget ally, maybe 0 toPrintedCost $ cdCost cardDef)
      let
        choice = chooseOne
          iid
          [ TargetLabel
              target
              [ ReturnToHand iid target
              , CreateEffect
                (toCardCode attrs)
                (Just $ EffectInt cost)
                (toSource attrs)
                (InvestigatorTarget iid)
              , Search
                iid
                (toSource attrs)
                (InvestigatorTarget iid)
                [fromTopOfDeck 9]
                IsAlly
                (PlayFound iid 1)
              ]
          | (target, cost) <- targetsWithCosts
          ]
      e <$ pushAll [choice, Discard (toTarget attrs)]
    _ -> CallingInFavors <$> runMessage msg attrs

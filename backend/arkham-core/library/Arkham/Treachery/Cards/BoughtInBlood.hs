module Arkham.Treachery.Cards.BoughtInBlood
  ( boughtInBlood
  , BoughtInBlood(..)
  ) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype BoughtInBlood = BoughtInBlood TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

boughtInBlood :: TreacheryCard BoughtInBlood
boughtInBlood = treachery BoughtInBlood Cards.boughtInBlood

instance RunMessage BoughtInBlood where
  runMessage msg t@(BoughtInBlood attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      inPlay <-
        selectList $ AssetControlledBy (InvestigatorWithId iid) <> AllyAsset
      inHand <- selectListMap toCardId $ InHandOf You <> BasicCardMatch IsAlly
      case (inPlay, inHand) of
        ([], []) -> push $ ShuffleIntoDeck iid (toTarget attrs)
        (inPlay', inHand') -> pushAll
          [ chooseOrRunOne
            iid
            ([ Label
                 "Discard an Ally asset you control from play"
                 [ChooseAndDiscardAsset iid AllyAsset]
             | notNull inPlay'
             ]
            <> [ Label "Discard each Ally asset from your hand"
                   $ map (DiscardCard iid) inHand'
               | notNull inHand'
               ]
            )
          , Discard $ toTarget attrs
          ]
      pure t
    _ -> BoughtInBlood <$> runMessage msg attrs

module Arkham.Treachery.Cards.RitesHowled
  ( ritesHowled
  , RitesHowled(..)
  ) where

import Arkham.Prelude

import Arkham.Treachery.Attrs
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner
import Arkham.Card
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.Id
import Arkham.Message
import Arkham.Trait

newtype RitesHowled = RitesHowled TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ritesHowled :: TreacheryCard RitesHowled
ritesHowled = treachery RitesHowled Cards.ritesHowled

instance TreacheryRunner env => RunMessage RitesHowled where
  runMessage msg t@(RitesHowled attrs) = case msg of
    Revelation _iid source | isSource attrs source -> do
      investigatorIds <- getInvestigatorIds
      t <$ pushAll
        ([ DiscardTopOfDeck iid 3 (Just $ toTarget attrs)
         | iid <- investigatorIds
         ]
        <> [Discard $ toTarget attrs]
        )
    DiscardedTopOfDeck iid _cards target | isTarget attrs target -> do
      isAltered <- member Altered <$> (getSet =<< getId @LocationId iid)
      t <$ when
        isAltered
        (do
          discardPile <- map unDiscardedPlayerCard <$> getList iid
          push $ ShuffleCardsIntoDeck
            iid
            (filter (isJust . cdCardSubType . toCardDef) discardPile)
        )
    _ -> RitesHowled <$> runMessage msg attrs

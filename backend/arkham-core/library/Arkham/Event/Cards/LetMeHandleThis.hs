module Arkham.Event.Cards.LetMeHandleThis
  ( letMeHandleThis
  , LetMeHandleThis(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Card
import Arkham.Classes
import Arkham.Event.Attrs
import Arkham.Message
import Arkham.Source
import Arkham.Target

newtype LetMeHandleThis = LetMeHandleThis EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor m, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

letMeHandleThis :: EventCard LetMeHandleThis
letMeHandleThis = event LetMeHandleThis Cards.letMeHandleThis

instance RunMessage LetMeHandleThis where
  runMessage msg e@(LetMeHandleThis attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid (Just (TreacheryTarget tid)) _ _
      | eid == eventId -> do
        withQueue_ $ map $ \case
          Revelation _ (TreacherySource tid') | tid == tid' ->
            Revelation iid (TreacherySource tid')
          AfterRevelation _ tid' | tid == tid' -> AfterRevelation iid tid'
          Surge _ (TreacherySource tid') | tid == tid' ->
            Surge iid (TreacherySource tid')
          other -> other
        e <$ pushAll
          [ CreateEffect
            (toCardCode attrs)
            Nothing
            (toSource attrs)
            (InvestigatorTarget iid)
          , Discard (toTarget attrs)
          ]
    _ -> LetMeHandleThis <$> runMessage msg attrs

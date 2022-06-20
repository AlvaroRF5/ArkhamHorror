module Arkham.Treachery.Cards.ArcaneBarrier
  ( ArcaneBarrier(..)
  , arcaneBarrier
  ) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.EffectMetadata
import Arkham.Investigator.Attrs
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Target
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype ArcaneBarrier = ArcaneBarrier TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arcaneBarrier :: TreacheryCard ArcaneBarrier
arcaneBarrier = treachery ArcaneBarrier Cards.arcaneBarrier

-- TODO: Move move to effect to a modifier...
instance RunMessage ArcaneBarrier where
  runMessage msg t@(ArcaneBarrier attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      mLocation <- field InvestigatorLocation iid
      for_ mLocation $ push . AttachTreachery (toId attrs) . idToTarget
      pure t
    Will (MoveTo _ iid lid) -> do
      shouldCostAdditional <-
        selectAny $ locationWithTreachery (toId attrs) <> LocationMatchAny
          [locationWithInvestigator iid, LocationWithId lid]
      when shouldCostAdditional $ do
        moveFromMessage <- fromJustNote "missing move from" <$> popMessage
        moveToMessage <- fromJustNote "missing move to" <$> popMessage
        push $ CreateEffect
          (toCardCode attrs)
          (Just $ EffectMessages [moveFromMessage, moveToMessage])
          (toSource attrs)
          (idToTarget iid)
      pure t
    _ -> ArcaneBarrier <$> runMessage msg attrs

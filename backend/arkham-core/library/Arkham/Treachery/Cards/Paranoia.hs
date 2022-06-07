module Arkham.Treachery.Cards.Paranoia where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Message
import Arkham.Projection
import Arkham.Treachery.Runner
import Arkham.Treachery.Cards qualified as Cards

newtype Paranoia = Paranoia TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

paranoia :: TreacheryCard Paranoia
paranoia = treachery Paranoia Cards.paranoia

instance RunMessage Paranoia where
  runMessage msg t@(Paranoia attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      resourceCount' <- field InvestigatorClues iid
      t <$ push (SpendResources iid resourceCount')
    _ -> Paranoia <$> runMessage msg attrs

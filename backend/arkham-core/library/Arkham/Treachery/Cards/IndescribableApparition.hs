module Arkham.Treachery.Cards.IndescribableApparition
  ( indescribableApparition
  , IndescribableApparition(..)
  )
where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Message
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype IndescribableApparition = IndescribableApparition TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

indescribableApparition :: TreacheryCard IndescribableApparition
indescribableApparition = treachery IndescribableApparition Cards.indescribableApparition

instance RunMessage IndescribableApparition where
  runMessage msg t@(IndescribableApparition attrs) = case msg of
    Revelation _iid (isSource attrs -> True) -> pure t
    _ -> IndescribableApparition <$> runMessage msg attrs

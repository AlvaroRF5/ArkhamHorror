module Arkham.Treachery.Cards.WhispersInYourHeadDoubt
  ( whispersInYourHeadDoubt
  , WhispersInYourHeadDoubt(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Card.CardType
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Message
import Arkham.Modifier
import Arkham.Target
import Arkham.Treachery.Attrs
import Arkham.Treachery.Helpers
import Arkham.Treachery.Runner

newtype WhispersInYourHeadDoubt = WhispersInYourHeadDoubt TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

whispersInYourHeadDoubt :: TreacheryCard WhispersInYourHeadDoubt
whispersInYourHeadDoubt =
  treachery WhispersInYourHeadDoubt Cards.whispersInYourHeadDoubt

instance HasModifiersFor env WhispersInYourHeadDoubt where
  getModifiersFor _ (InvestigatorHandTarget _) (WhispersInYourHeadDoubt a) = pure $ toModifiers a [CannotPlay [(EventType, mempty)]]
  getModifiersFor _ _ _ = pure []

instance HasAbilities WhispersInYourHeadDoubt where
  getAbilities (WhispersInYourHeadDoubt a) =
    [restrictedAbility a 1 InYourHand $ ActionAbility Nothing $ ActionCost 2]

instance TreacheryRunner env => RunMessage WhispersInYourHeadDoubt where
  runMessage msg t@(WhispersInYourHeadDoubt attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AddTreacheryToHand iid $ toId attrs)
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      t <$ push (Discard $ toTarget attrs)
    _ -> WhispersInYourHeadDoubt <$> runMessage msg attrs

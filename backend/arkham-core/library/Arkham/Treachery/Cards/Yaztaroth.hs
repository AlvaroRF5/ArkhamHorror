module Arkham.Treachery.Cards.Yaztaroth
  ( yaztaroth
  , Yaztaroth(..)
  )
where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.Message
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype Yaztaroth = Yaztaroth TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

yaztaroth :: TreacheryCard Yaztaroth
yaztaroth = treachery Yaztaroth Cards.yaztaroth

instance HasModifiersFor Yaztaroth where
  getModifiersFor (InvestigatorTarget iid) (Yaztaroth attrs) =
    pure $ toModifiers attrs $ do
     guard $ treacheryOnInvestigator iid attrs
     [ CannotPlay AssetCard, CannotPutIntoPlay AssetCard]
  getModifiersFor _ _ = pure []

instance HasAbilities Yaztaroth where
  getAbilities (Yaztaroth a) =
    [ restrictedAbility a 1 OnSameLocation $ ActionAbility Nothing $ ActionCost
      2
    ]

instance RunMessage Yaztaroth where
  runMessage msg t@(Yaztaroth attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AttachTreachery (toId attrs) $ InvestigatorTarget iid)
    UseCardAbility _ source 1 _ _ | isSource attrs source -> do
      push $ Discard (toAbilitySource attrs 2) (toTarget attrs)
      pure t
    _ -> Yaztaroth <$> runMessage msg attrs

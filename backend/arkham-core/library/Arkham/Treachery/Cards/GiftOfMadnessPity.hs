module Arkham.Treachery.Cards.GiftOfMadnessPity (
  giftOfMadnessPity,
  GiftOfMadnessPity (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Matcher hiding (PlaceUnderneath, treacheryInHandOf)
import Arkham.Modifier
import Arkham.Scenario.Deck
import Arkham.Trait
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Helpers
import Arkham.Treachery.Runner

newtype GiftOfMadnessPity = GiftOfMadnessPity TreacheryAttrs
  deriving anyclass (IsTreachery)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

giftOfMadnessPity :: TreacheryCard GiftOfMadnessPity
giftOfMadnessPity = treachery GiftOfMadnessPity Cards.giftOfMadnessPity

instance HasModifiersFor GiftOfMadnessPity where
  getModifiersFor (InvestigatorTarget iid) (GiftOfMadnessPity a) =
    pure
      $ toModifiers
        a
        [CannotFight (EnemyWithTrait Lunatic) | treacheryInHandOf a == Just iid]
  getModifiersFor _ _ = pure []

instance HasAbilities GiftOfMadnessPity where
  getAbilities (GiftOfMadnessPity a) =
    [restrictedAbility a 1 InYourHand actionAbility]

instance RunMessage GiftOfMadnessPity where
  runMessage msg t@(GiftOfMadnessPity attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      t <$ push (addHiddenToHand iid attrs)
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      pushAll
        [ DrawRandomFromScenarioDeck iid MonstersDeck (toTarget attrs) 1
        , toDiscardBy iid (toAbilitySource attrs 1) attrs
        ]
      pure t
    DrewFromScenarioDeck _ _ target cards | isTarget attrs target -> do
      t <$ push (PlaceUnderneath ActDeckTarget cards)
    _ -> GiftOfMadnessPity <$> runMessage msg attrs

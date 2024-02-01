module Arkham.Treachery.Cards.PossessionTorturous (
  possessionTorturous,
  PossessionTorturous (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Investigator.Types (Field (..))
import Arkham.Projection
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype PossessionTorturous = PossessionTorturous TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks)

possessionTorturous :: TreacheryCard PossessionTorturous
possessionTorturous = treachery PossessionTorturous Cards.possessionTorturous

instance HasAbilities PossessionTorturous where
  getAbilities (PossessionTorturous a) =
    [ restrictedAbility a 1 InYourHand
        $ ActionAbility [] (ActionCost 1 <> ResourceCost 5)
    ]

instance RunMessage PossessionTorturous where
  runMessage msg t@(PossessionTorturous attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      horror <- field InvestigatorHorror iid
      sanity <- field InvestigatorSanity iid
      pushWhen (horror > sanity * 2)
        $ InvestigatorKilled (toSource attrs) iid
      push $ PlaceTreachery (toId attrs) (TreacheryInHandOf iid)
      pure t
    EndCheckWindow {} -> case treacheryInHandOf attrs of
      Just iid -> do
        horror <- field InvestigatorHorror iid
        sanity <- field InvestigatorSanity iid
        pushWhen (horror > sanity * 2)
          $ InvestigatorKilled (toSource attrs) iid
        pure t
      Nothing -> pure t
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      push $ toDiscardBy iid (toAbilitySource attrs 1) attrs
      pure t
    _ -> PossessionTorturous <$> runMessage msg attrs

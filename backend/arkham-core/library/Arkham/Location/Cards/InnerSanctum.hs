module Arkham.Location.Cards.InnerSanctum (
  innerSanctum,
  InnerSanctum (..),
)
where

import Arkham.Prelude

import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Key
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Scenarios.ForTheGreaterGood.Helpers
import Arkham.Timing qualified as Timing

newtype InnerSanctum = InnerSanctum LocationAttrs
  deriving anyclass (IsLocation)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

innerSanctum :: LocationCard InnerSanctum
innerSanctum = location InnerSanctum Cards.innerSanctum 4 (PerPlayer 1)

instance HasModifiersFor InnerSanctum where
  getModifiersFor (InvestigatorTarget iid) (InnerSanctum attrs) = do
    hasElderThingKey <- iid <=~> InvestigatorWithKey ElderThingKey
    pure $ toModifiers attrs [CannotEnter (toId attrs) | unrevealed attrs && not hasElderThingKey]
  getModifiersFor _ _ = pure []

instance HasAbilities InnerSanctum where
  getAbilities (InnerSanctum attrs) =
    withRevealedAbilities
      attrs
      [mkAbility attrs 1 $ ForcedAbility $ RevealLocation Timing.After You $ LocationWithId $ toId attrs]

instance RunMessage InnerSanctum where
  runMessage msg l@(InnerSanctum attrs) = case msg of
    UseCardAbility _ (isSource attrs -> True) 1 _ _ -> do
      key <- getRandomKey
      push $ PlaceKey (toTarget attrs) key
      pure l
    _ -> InnerSanctum <$> runMessage msg attrs

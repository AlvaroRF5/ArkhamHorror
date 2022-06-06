module Arkham.Location.Cards.BlastedHeath_249
  ( blastedHeath_249
  , BlastedHeath_249(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (blastedHeath_249)
import Arkham.Classes
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing

newtype BlastedHeath_249 = BlastedHeath_249 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

blastedHeath_249 :: LocationCard BlastedHeath_249
blastedHeath_249 = location
  BlastedHeath_249
  Cards.blastedHeath_249
  3
  (Static 2)
  Square
  [Circle, Hourglass]

instance HasAbilities BlastedHeath_249 where
  getAbilities (BlastedHeath_249 attrs) =
    withBaseAbilities attrs $
      [ restrictedAbility attrs 1 Here $ ForcedAbility $ TurnEnds
          Timing.When
          You
      | locationRevealed attrs
      ]

instance RunMessage BlastedHeath_249 where
  runMessage msg l@(BlastedHeath_249 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ push (InvestigatorAssignDamage iid source DamageAny 1 0)
    _ -> BlastedHeath_249 <$> runMessage msg attrs

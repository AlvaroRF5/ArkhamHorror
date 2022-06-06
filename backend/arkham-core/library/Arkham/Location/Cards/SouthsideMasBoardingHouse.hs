module Arkham.Location.Cards.SouthsideMasBoardingHouse
  ( SouthsideMasBoardingHouse(..)
  , southsideMasBoardingHouse
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (southsideMasBoardingHouse)
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype SouthsideMasBoardingHouse = SouthsideMasBoardingHouse LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

southsideMasBoardingHouse :: LocationCard SouthsideMasBoardingHouse
southsideMasBoardingHouse = location
  SouthsideMasBoardingHouse
  Cards.southsideMasBoardingHouse
  2
  (PerPlayer 1)
  Square
  [Diamond, Plus, Circle]

instance HasAbilities SouthsideMasBoardingHouse where
  getAbilities (SouthsideMasBoardingHouse x) | locationRevealed x =
    withBaseAbilities x
      $ [ restrictedAbility x 1 Here (ActionAbility Nothing $ ActionCost 1)
          & abilityLimitL
          .~ PlayerLimit PerGame 1
        ]
  getAbilities (SouthsideMasBoardingHouse attrs) = getAbilities attrs

instance RunMessage SouthsideMasBoardingHouse where
  runMessage msg l@(SouthsideMasBoardingHouse attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> l <$ push
      (Search iid source (InvestigatorTarget iid) [fromDeck] IsAlly
      $ DrawFound iid 1
      )
    _ -> SouthsideMasBoardingHouse <$> runMessage msg attrs

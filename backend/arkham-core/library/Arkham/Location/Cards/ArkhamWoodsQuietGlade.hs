module Arkham.Location.Cards.ArkhamWoodsQuietGlade
  ( ArkhamWoodsQuietGlade(..)
  , arkhamWoodsQuietGlade
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (arkhamWoodsQuietGlade)
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Message
import Arkham.Source
import Arkham.Target

newtype ArkhamWoodsQuietGlade = ArkhamWoodsQuietGlade LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arkhamWoodsQuietGlade :: LocationCard ArkhamWoodsQuietGlade
arkhamWoodsQuietGlade = locationWithRevealedSideConnections
  ArkhamWoodsQuietGlade
  Cards.arkhamWoodsQuietGlade
  1
  (Static 0)
  Square
  [Squiggle]
  Moon
  [Squiggle, Equals, Hourglass]

instance HasAbilities ArkhamWoodsQuietGlade where
  getAbilities (ArkhamWoodsQuietGlade attrs) | locationRevealed attrs =
    withBaseAbilities attrs
      $ [ restrictedAbility attrs 1 Here (ActionAbility Nothing $ ActionCost 1)
          & abilityLimitL
          .~ PlayerLimit PerTurn 1
        ]
  getAbilities (ArkhamWoodsQuietGlade attrs) = getAbilities attrs

instance LocationRunner env => RunMessage ArkhamWoodsQuietGlade where
  runMessage msg l@(ArkhamWoodsQuietGlade attrs@LocationAttrs {..}) =
    case msg of
      UseCardAbility iid (LocationSource lid) _ 1 _ | lid == locationId ->
        l <$ pushAll
          [ HealDamage (InvestigatorTarget iid) 1
          , HealHorror (InvestigatorTarget iid) 1
          ]
      _ -> ArkhamWoodsQuietGlade <$> runMessage msg attrs

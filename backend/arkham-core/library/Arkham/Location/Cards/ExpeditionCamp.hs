module Arkham.Location.Cards.ExpeditionCamp
  ( expeditionCamp
  , ExpeditionCamp(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Campaigns.TheForgottenAge.Supply
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Helpers.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Message

newtype ExpeditionCamp = ExpeditionCamp LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

expeditionCamp :: LocationCard ExpeditionCamp
expeditionCamp = location
  ExpeditionCamp
  Cards.expeditionCamp
  1
  (Static 0)
  Circle
  [Square, Diamond, Moon]

instance HasAbilities ExpeditionCamp where
  getAbilities (ExpeditionCamp attrs) =
    withBaseAbilities attrs $ if locationRevealed attrs
      then
        [ withTooltip
          "The wilds are too dangerous!"
          (locationResignAction attrs)
        , restrictedAbility
          attrs
          2
          (Here <> HasSupply Map)
          (ActionAbility Nothing $ ActionCost 1)
        ]
      else []

instance RunMessage ExpeditionCamp where
  runMessage msg l@(ExpeditionCamp attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> pure l
    _ -> ExpeditionCamp <$> runMessage msg attrs

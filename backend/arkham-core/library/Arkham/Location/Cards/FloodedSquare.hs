module Arkham.Location.Cards.FloodedSquare
  ( floodedSquare
  , FloodedSquare(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Scenarios.CarnevaleOfHorrors.Helpers
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Direction
import Arkham.GameValue
import Arkham.Id
import Arkham.Location.Attrs
import Arkham.Location.Helpers
import Arkham.Matcher hiding (EnemyEvaded)
import Arkham.Message
import Arkham.Target

newtype FloodedSquare = FloodedSquare LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

floodedSquare :: LocationCard FloodedSquare
floodedSquare = locationWith
  FloodedSquare
  Cards.floodedSquare
  4
  (PerPlayer 1)
  NoSymbol
  []
  (connectsToL .~ singleton RightOf)

instance HasAbilities FloodedSquare where
  getAbilities (FloodedSquare attrs) =
    withBaseAbilities attrs
      $ [ restrictedAbility
            attrs
            1
            (EnemyCriteria $ EnemyExists $ NonEliteEnemy <> EnemyAt
              (LocationInDirection RightOf $ LocationWithId $ toId attrs)
            )
          $ ActionAbility Nothing
          $ ActionCost 1
        | locationRevealed attrs
        ]

instance LocationRunner env => RunMessage env FloodedSquare where
  runMessage msg l@(FloodedSquare attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      counterClockwiseLocation <- getCounterClockwiseLocation (toId attrs)
      nonEliteEnemies <- getSetList @EnemyId $ EnemyMatchAll
        [NonEliteEnemy, EnemyAt $ LocationWithId counterClockwiseLocation]
      l <$ push
        (chooseOne
          iid
          [ TargetLabel (EnemyTarget eid) [EnemyEvaded iid eid]
          | eid <- nonEliteEnemies
          ]
        )
    _ -> FloodedSquare <$> runMessage msg attrs

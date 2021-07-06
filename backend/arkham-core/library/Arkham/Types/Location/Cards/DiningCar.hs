module Arkham.Types.Location.Cards.DiningCar
  ( diningCar
  , DiningCar(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (diningCar)
import Arkham.Types.Card.CardMatcher
import Arkham.Types.Classes
import Arkham.Types.Direction
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Query

newtype DiningCar = DiningCar LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

diningCar :: LocationCard DiningCar
diningCar = locationWith
  DiningCar
  Cards.diningCar
  2
  (Static 0)
  NoSymbol
  []
  (connectsToL .~ setFromList [LeftOf, RightOf])

instance HasCount ClueCount env LocationId => HasModifiersFor env DiningCar where
  getModifiersFor _ target (DiningCar l@LocationAttrs {..})
    | isTarget l target = case lookup LeftOf locationDirections of
      Just leftLocation -> do
        clueCount <- unClueCount <$> getCount leftLocation
        pure $ toModifiers l [ Blocked | not locationRevealed && clueCount > 0 ]
      Nothing -> pure []
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env DiningCar where
  getActions iid window (DiningCar attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env DiningCar where
  runMessage msg (DiningCar attrs) = case msg of
    RevealLocation (Just iid) lid | lid == locationId attrs -> do
      push (FindAndDrawEncounterCard iid (CardMatchByCardCode "02182"))
      DiningCar <$> runMessage msg attrs
    _ -> DiningCar <$> runMessage msg attrs

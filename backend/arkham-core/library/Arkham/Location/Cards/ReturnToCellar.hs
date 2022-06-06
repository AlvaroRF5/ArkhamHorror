module Arkham.Location.Cards.ReturnToCellar
  ( returnToCellar
  , ReturnToCellar(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message hiding (RevealLocation)
import Arkham.Timing qualified as Timing

newtype ReturnToCellar = ReturnToCellar LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

returnToCellar :: LocationCard ReturnToCellar
returnToCellar = location
  ReturnToCellar
  Cards.returnToCellar
  2
  (PerPlayer 1)
  Plus
  [Square, Squiggle]

instance HasAbilities ReturnToCellar where
  getAbilities (ReturnToCellar attrs) =
    withBaseAbilities attrs
      $ [ mkAbility attrs 1
          $ ForcedAbility
          $ RevealLocation Timing.After You
          $ LocationWithId
          $ toId attrs
        | locationRevealed attrs
        ]

instance (LocationRunner env) => RunMessage ReturnToCellar where
  runMessage msg l@(ReturnToCellar attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      deepBelowYourHouse <- getSetAsideCard Cards.deepBelowYourHouse
      l <$ push (PlaceLocation deepBelowYourHouse)
    _ -> ReturnToCellar <$> runMessage msg attrs

module Arkham.Location.Cards.ReturnToAttic
  ( returnToAttic
  , ReturnToAttic(..)
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

newtype ReturnToAttic = ReturnToAttic LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

returnToAttic :: LocationCard ReturnToAttic
returnToAttic = location
  ReturnToAttic
  Cards.returnToAttic
  3
  (PerPlayer 1)
  Triangle
  [Square, Moon]

instance HasAbilities ReturnToAttic where
  getAbilities (ReturnToAttic attrs) =
    withBaseAbilities attrs
      $ [ mkAbility attrs 1
          $ ForcedAbility
          $ RevealLocation Timing.After You
          $ LocationWithId
          $ toId attrs
        | locationRevealed attrs
        ]

instance (LocationRunner env) => RunMessage env ReturnToAttic where
  runMessage msg l@(ReturnToAttic attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      farAboveYourHouse <- getSetAsideCard Cards.farAboveYourHouse
      l <$ push (PlaceLocation farAboveYourHouse)
    _ -> ReturnToAttic <$> runMessage msg attrs

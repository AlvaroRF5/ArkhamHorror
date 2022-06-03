module Arkham.Location.Cards.TheGuardian
  ( theGuardian
  , TheGuardian(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Classes
import Arkham.Cost
import Arkham.Direction
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing

newtype TheGuardian = TheGuardian LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theGuardian :: LocationCard TheGuardian
theGuardian = locationWith
  TheGuardian
  Cards.theGuardian
  3
  (PerPlayer 2)
  NoSymbol
  []
  (connectsToL .~ singleton RightOf)

instance HasAbilities TheGuardian where
  getAbilities (TheGuardian attrs) =
    withBaseAbilities attrs $
      [ mkAbility attrs 1
          $ ReactionAbility
              (Enters Timing.After You $ LocationWithId $ toId attrs)
              Free
      | locationRevealed attrs
      ]

instance LocationRunner env => RunMessage TheGuardian where
  runMessage msg l@(TheGuardian attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ push (DrawCards iid 1 False)
    _ -> TheGuardian <$> runMessage msg attrs

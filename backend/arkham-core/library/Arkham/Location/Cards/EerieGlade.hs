module Arkham.Location.Cards.EerieGlade
  ( eerieGlade
  , EerieGlade(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (eerieGlade)
import Arkham.Classes
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message hiding (RevealLocation)
import Arkham.Query
import Arkham.Timing qualified as Timing

newtype EerieGlade = EerieGlade LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

eerieGlade :: LocationCard EerieGlade
eerieGlade = locationWith
  EerieGlade
  Cards.eerieGlade
  4
  (PerPlayer 1)
  NoSymbol
  []
  ((revealedSymbolL .~ Hourglass)
  . (revealedConnectedMatchersL .~ map LocationWithSymbol [Triangle, Plus])
  )

instance HasAbilities EerieGlade where
  getAbilities (EerieGlade attrs) =
    withBaseAbilities attrs
      $ [ restrictedAbility
            attrs
            1
            (InvestigatorExists $ You <> InvestigatorWithAnyActionsRemaining)
          $ ForcedAbility
          $ RevealLocation Timing.After You
          $ LocationWithId
          $ toId attrs
        | locationRevealed attrs
        ]

instance LocationRunner env => RunMessage env EerieGlade where
  runMessage msg l@(EerieGlade attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      actionRemainingCount <- unActionRemainingCount <$> getCount iid
      l <$ push (DiscardTopOfDeck iid (actionRemainingCount * 2) Nothing)
    _ -> EerieGlade <$> runMessage msg attrs

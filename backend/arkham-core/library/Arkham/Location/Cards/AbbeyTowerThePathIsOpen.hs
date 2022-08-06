module Arkham.Location.Cards.AbbeyTowerThePathIsOpen
  ( abbeyTowerThePathIsOpen
  , AbbeyTowerThePathIsOpen(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Helpers.Log
import Arkham.Helpers.Modifiers
import Arkham.Investigator.Types ( Field (InvestigatorHand) )
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.ScenarioLogKey
import Arkham.Target

newtype AbbeyTowerThePathIsOpen = AbbeyTowerThePathIsOpen LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

abbeyTowerThePathIsOpen :: LocationCard AbbeyTowerThePathIsOpen
abbeyTowerThePathIsOpen =
  location AbbeyTowerThePathIsOpen Cards.abbeyTowerThePathIsOpen 3 (PerPlayer 2)

instance HasModifiersFor AbbeyTowerThePathIsOpen where
  getModifiersFor _ target (AbbeyTowerThePathIsOpen attrs)
    | isTarget attrs target = do
      foundAGuide <- remembered FoundTheTowerKey
      pure $ toModifiers
        attrs
        [ Blocked | not (locationRevealed attrs) && not foundAGuide ]
  getModifiersFor _ (InvestigatorTarget iid) (AbbeyTowerThePathIsOpen attrs)
    | iid `member` locationInvestigators attrs = do
      cardsInHand <- fieldMap InvestigatorHand length iid
      pure $ toModifiers attrs [ CannotDiscoverClues | cardsInHand == 0 ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities AbbeyTowerThePathIsOpen where
  getAbilities (AbbeyTowerThePathIsOpen a) = withBaseAbilities
    a
    [ restrictedAbility
        a
        1
        (Here <> InvestigatorExists (You <> HandWith (HasCard NonWeakness)))
      $ ActionAbility Nothing
      $ ActionCost 1
    ]

instance RunMessage AbbeyTowerThePathIsOpen where
  runMessage msg l@(AbbeyTowerThePathIsOpen attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      maxDiscardAmount <-
        selectCount
        $ InHandOf (InvestigatorWithId iid)
        <> BasicCardMatch NonWeakness
      push $ chooseAmounts
        iid
        "Discard up to 3 cards from your hand"
        3
        [("Cards", (0, maxDiscardAmount))]
        (toTarget attrs)
      pure l
    ResolveAmounts iid choices target | isTarget attrs target -> do
      let
        choicesMap = mapFromList @(HashMap Text Int) choices
        discardAmount = findWithDefault 0 "Cards" choicesMap
      when (discardAmount > 0) $ pushAll $ replicate
        discardAmount
        (ChooseAndDiscardCard iid)
      pure l
    _ -> AbbeyTowerThePathIsOpen <$> runMessage msg attrs

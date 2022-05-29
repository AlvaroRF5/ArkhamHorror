module Arkham.Location.Cards.WellOfSouls
  ( wellOfSouls
  , WellOfSouls(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Direction
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message hiding ( RevealLocation )
import Arkham.Scenario.Deck
import Arkham.Scenarios.ThePallidMask.Helpers
import Arkham.Timing qualified as Timing

newtype WellOfSouls = WellOfSouls LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wellOfSouls :: LocationCard WellOfSouls
wellOfSouls = locationWith
  WellOfSouls
  Cards.wellOfSouls
  4
  (PerPlayer 1)
  NoSymbol
  []
  ((connectsToL .~ adjacentLocations)
  . (costToEnterUnrevealedL
    .~ Costs [ActionCost 1, GroupClueCost (PerPlayer 1) YourLocation]
    )
  )

instance HasAbilities WellOfSouls where
  getAbilities (WellOfSouls attrs) =
    withBaseAbilities attrs $ if locationRevealed attrs
      then
        [ restrictedAbility attrs 1 Here $ ForcedAbility $ TurnEnds Timing.After You
        , restrictedAbility
            attrs
            2
            (AnyCriterion
              [ Negate
                  (LocationExists
                  $ LocationInDirection dir (LocationWithId $ toId attrs)
                  )
              | dir <- [Above, Below, RightOf]
              ]
            )
          $ ForcedAbility
          $ RevealLocation Timing.When Anyone
          $ LocationWithId
          $ toId attrs
        ]
      else []

instance LocationRunner env => RunMessage env WellOfSouls where
  runMessage msg l@(WellOfSouls attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) _ 1 _ -> do
      hasCardsInHand <- selectAny $ InHandOf (InvestigatorWithId iid)
      push
        $ chooseOrRunOne iid
        $ Label
            "Take 1 direct horror"
            [InvestigatorDirectDamage iid (toSource attrs) 0 1]
        : [ Label
              "Discard 2 random cards from your hand"
              [RandomDiscard iid, RandomDiscard iid]
          | hasCardsInHand
          ]
      pure l
    UseCardAbility iid (isSource attrs -> True) _ 2 _ -> do
      push (DrawFromScenarioDeck iid CatacombsDeck (toTarget attrs) 1)
      pure l
    DrewFromScenarioDeck iid _ (isTarget attrs -> True) cards -> do
      case cards of
        [card] -> do
          placeAbove <- placeAtDirection Above attrs <*> pure card
          placeBelow <- placeAtDirection Below attrs <*> pure card
          placeRight <- placeAtDirection RightOf attrs <*> pure card
          aboveEmpty <- directionEmpty attrs Above
          belowEmpty <- directionEmpty attrs Below
          rightEmpty <- directionEmpty attrs RightOf
          push
            $ chooseOrRunOne iid
            $ [ Label "Place Above" placeAbove | aboveEmpty ]
            <> [ Label "Place Below" placeBelow | belowEmpty ]
            <> [ Label "Place to the Right" placeRight | rightEmpty ]
        [] -> pure ()
        _ -> error "wrong number of cards drawn"
      pure l
    _ -> WellOfSouls <$> runMessage msg attrs

module Arkham.Location.Cards.StoneArchways
  ( stoneArchways
  , StoneArchways(..)
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
import Arkham.Modifier
import Arkham.Scenario.Deck
import Arkham.Scenarios.ThePallidMask.Helpers
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype StoneArchways = StoneArchways LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

stoneArchways :: LocationCard StoneArchways
stoneArchways = locationWith
  StoneArchways
  Cards.stoneArchways
  2
  (Static 0)
  NoSymbol
  []
  ((connectsToL .~ adjacentLocations)
  . (costToEnterUnrevealedL
    .~ Costs [ActionCost 1, GroupClueCost (PerPlayer 1) YourLocation]
    )
  )

instance Query LocationMatcher env => HasModifiersFor StoneArchways where
  getModifiersFor _ (LocationTarget lid) (StoneArchways attrs) = do
    isUnrevealedAdjacent <- member lid <$> select
      (UnrevealedLocation <> LocationMatchAny
        [ LocationInDirection dir (LocationWithId $ toId attrs)
        | dir <- [minBound .. maxBound]
        ]
      )
    pure $ toModifiers attrs [ Blank | isUnrevealedAdjacent ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities StoneArchways where
  getAbilities (StoneArchways attrs) = withBaseAbilities
    attrs
    [ restrictedAbility
        attrs
        1
        (Negate
          (LocationExists
          $ LocationInDirection RightOf (LocationWithId $ toId attrs)
          )
        )
      $ ForcedAbility
      $ RevealLocation Timing.When Anyone
      $ LocationWithId
      $ toId attrs
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage StoneArchways where
  runMessage msg l@(StoneArchways attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) _ 1 _ -> do
      push (DrawFromScenarioDeck iid CatacombsDeck (toTarget attrs) 1)
      pure l
    DrewFromScenarioDeck _ _ (isTarget attrs -> True) cards -> do
      case cards of
        [card] -> do
          msgs <- placeAtDirection RightOf attrs <*> pure card
          pushAll msgs
        [] -> pure ()
        _ -> error "wrong number of cards drawn"
      pure l
    _ -> StoneArchways <$> runMessage msg attrs

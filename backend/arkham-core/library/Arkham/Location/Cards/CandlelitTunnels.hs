module Arkham.Location.Cards.CandlelitTunnels
  ( candlelitTunnels
  , CandlelitTunnels(..)
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
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype CandlelitTunnels = CandlelitTunnels LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

candlelitTunnels :: LocationCard CandlelitTunnels
candlelitTunnels = locationWith
  CandlelitTunnels
  Cards.candlelitTunnels
  3
  (PerPlayer 2)
  NoSymbol
  []
  ((connectsToL .~ adjacentLocations)
  . (costToEnterUnrevealedL
    .~ Costs [ActionCost 1, GroupClueCost (PerPlayer 1) YourLocation]
    )
  )

instance HasAbilities CandlelitTunnels where
  getAbilities (CandlelitTunnels attrs) =
    withBaseAbilities attrs $ if locationRevealed attrs
      then
        [ limitedAbility (GroupLimit PerGame 1)
        $ restrictedAbility attrs 1 Here
        $ ActionAbility Nothing (ActionCost 1)
        , restrictedAbility
          attrs
          2
          (AnyCriterion
            [ Negate
                (LocationExists
                $ LocationInDirection dir (LocationWithId $ toId attrs)
                )
            | dir <- [LeftOf, RightOf]
            ]
          )
        $ ForcedAbility
        $ RevealLocation Timing.When Anyone
        $ LocationWithId
        $ toId attrs
        ]
      else []

instance RunMessage CandlelitTunnels where
  runMessage msg l@(CandlelitTunnels attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) _ 1 _ -> do
      push $ BeginSkillTest
        iid
        (toSource attrs)
        (toTarget attrs)
        Nothing
        SkillIntellect
        3
      pure l
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        locations <- selectList UnrevealedLocation
        unless (null locations) $ push $ chooseOne
          iid
          [ targetLabel lid [LookAtRevealed source (LocationTarget lid)]
          | lid <- locations
          ]
        pure l
    UseCardAbility iid (isSource attrs -> True) _ 2 _ -> do
      n <- countM (directionEmpty attrs) [LeftOf, RightOf]
      push (DrawFromScenarioDeck iid CatacombsDeck (toTarget attrs) n)
      pure l
    DrewFromScenarioDeck _ _ (isTarget attrs -> True) cards -> do
      placements <- mapMaybeM (toMaybePlacement attrs) [LeftOf, RightOf]
      pushAll $ concat $ zipWith ($) placements cards
      pure l
    _ -> CandlelitTunnels <$> runMessage msg attrs

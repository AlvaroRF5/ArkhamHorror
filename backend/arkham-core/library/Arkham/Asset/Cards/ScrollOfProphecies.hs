module Arkham.Asset.Cards.ScrollOfProphecies
  ( ScrollOfProphecies(..)
  , scrollOfProphecies
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher

newtype ScrollOfProphecies = ScrollOfProphecies AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

scrollOfProphecies :: AssetCard ScrollOfProphecies
scrollOfProphecies = asset ScrollOfProphecies Cards.scrollOfProphecies

instance HasAbilities ScrollOfProphecies where
  getAbilities (ScrollOfProphecies x) =
    [ restrictedAbility x 1 ControlsThis $ ActionAbility Nothing $ Costs
        [ActionCost 1, UseCost (AssetWithId $ toId x) Secret 1]
    ]

instance RunMessage ScrollOfProphecies where
  runMessage msg a@(ScrollOfProphecies attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      investigatorIds <- selectList $ colocatedWith iid
      investigators <- forToSnd investigatorIds $ \i -> drawCards i attrs 3
      push $ chooseOne
        iid
        [ targetLabel iid' [drawing, ChooseAndDiscardCard iid' (toAbilitySource attrs 1)]
        | (iid', drawing) <- investigators
        ]
      pure a
    _ -> ScrollOfProphecies <$> runMessage msg attrs

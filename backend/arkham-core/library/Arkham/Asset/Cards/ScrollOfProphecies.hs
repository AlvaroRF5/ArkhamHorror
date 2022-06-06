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
import Arkham.Id
import Arkham.Matcher
import Arkham.Target

newtype ScrollOfProphecies = ScrollOfProphecies AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

scrollOfProphecies :: AssetCard ScrollOfProphecies
scrollOfProphecies = asset ScrollOfProphecies Cards.scrollOfProphecies

instance HasAbilities ScrollOfProphecies where
  getAbilities (ScrollOfProphecies x) =
    [ restrictedAbility
        x
        1
        OwnsThis
        (ActionAbility Nothing $ Costs [ActionCost 1, UseCost (AssetWithId $ toId x) Secret 1]
        )
    ]

instance RunMessage ScrollOfProphecies where
  runMessage msg a@(ScrollOfProphecies attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      locationId <- getId @LocationId iid
      investigatorIds <- getSetList locationId
      a <$ push
        (chooseOne
          iid
          [ TargetLabel
              (InvestigatorTarget iid')
              [DrawCards iid' 3 False, ChooseAndDiscardCard iid']
          | iid' <- investigatorIds
          ]
        )
    _ -> ScrollOfProphecies <$> runMessage msg attrs

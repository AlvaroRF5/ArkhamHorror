module Arkham.Asset.Cards.Pickpocketing
  ( Pickpocketing(..)
  , pickpocketing
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Matcher qualified as Matcher
import Arkham.Timing qualified as Timing

newtype Pickpocketing = Pickpocketing AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

pickpocketing :: AssetCard Pickpocketing
pickpocketing = asset Pickpocketing Cards.pickpocketing

instance HasAbilities Pickpocketing where
  getAbilities (Pickpocketing a) =
    [ restrictedAbility a 1 OwnsThis $ ReactionAbility
        (Matcher.EnemyEvaded Timing.After You AnyEnemy)
        (ExhaustCost $ toTarget a)
    ]

instance AssetRunner env => RunMessage Pickpocketing where
  runMessage msg a@(Pickpocketing attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (DrawCards iid 1 False)
    _ -> Pickpocketing <$> runMessage msg attrs

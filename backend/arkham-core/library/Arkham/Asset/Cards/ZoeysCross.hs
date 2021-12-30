module Arkham.Asset.Cards.ZoeysCross
  ( ZoeysCross(..)
  , zoeysCross
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.DamageEffect
import Arkham.Matcher hiding (NonAttackDamageEffect)
import Arkham.Timing qualified as Timing
import Arkham.Window (Window(..))
import Arkham.Window qualified as Window

newtype ZoeysCross = ZoeysCross AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

zoeysCross :: AssetCard ZoeysCross
zoeysCross = asset ZoeysCross Cards.zoeysCross

instance HasAbilities ZoeysCross where
  getAbilities (ZoeysCross x) =
    [ restrictedAbility x 1 OwnsThis
        $ ReactionAbility (EnemyEngaged Timing.After You AnyEnemy)
        $ Costs [ExhaustCost (toTarget x), ResourceCost 1]
    ]

instance (AssetRunner env) => RunMessage env ZoeysCross where
  runMessage msg a@(ZoeysCross attrs) = case msg of
    UseCardAbility iid source [Window _ (Window.EnemyEngaged _ eid)] 1 _
      | isSource attrs source -> a
      <$ push (EnemyDamage eid iid source NonAttackDamageEffect 1)
    _ -> ZoeysCross <$> runMessage msg attrs

module Arkham.Asset.Cards.FishingNet
  ( FishingNet(..)
  , fishingNet
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Keyword
import Arkham.Matcher
import Arkham.Target

newtype FishingNet = FishingNet AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fishingNet :: AssetCard FishingNet
fishingNet = assetWith FishingNet Cards.fishingNet (isStoryL .~ True)

instance HasModifiersFor FishingNet where
  getModifiersFor _ (EnemyTarget eid) (FishingNet attrs) = pure $ toModifiers
    attrs
    [ RemoveKeyword Retaliate | assetEnemy attrs == Just eid ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities FishingNet where
  getAbilities (FishingNet x) =
    [restrictedAbility x 1 restriction $ FastAbility Free]
   where
    restriction = case assetEnemy x of
      Just _ -> Never
      Nothing -> OwnsThis <> EnemyCriteria
        (EnemyExists
        $ ExhaustedEnemy
        <> EnemyAt YourLocation
        <> enemyIs Cards.theRougarou
        )

instance RunMessage FishingNet where
  runMessage msg a@(FishingNet attrs@AssetAttrs {..}) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      mrougarou <- selectOne $ enemyIs Cards.theRougarou
      case mrougarou of
        Nothing -> error "can not use this ability"
        Just eid -> a <$ push (AttachAsset assetId (EnemyTarget eid))
    _ -> FishingNet <$> runMessage msg attrs

module Arkham.Enemy.Cards.BroodOfYogSothoth
  ( BroodOfYogSothoth(..)
  , broodOfYogSothoth
  ) where

import Arkham.Prelude

import Arkham.Enemy.Cards qualified as Cards
import Arkham.Card.CardCode
import Arkham.Classes
import Arkham.Asset.Attrs (Field(..))
import Arkham.Enemy.Runner
import Arkham.Message qualified as Msg
import Arkham.Name
import Arkham.Projection
import Arkham.Source

newtype BroodOfYogSothoth = BroodOfYogSothoth EnemyAttrs
  deriving anyclass IsEnemy
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

broodOfYogSothoth :: EnemyCard BroodOfYogSothoth
broodOfYogSothoth =
  enemy BroodOfYogSothoth Cards.broodOfYogSothoth (6, Static 1, 3) (2, 2)

instance HasModifiersFor BroodOfYogSothoth where
  getModifiersFor _ target (BroodOfYogSothoth a) | isTarget a target = do
    healthModifier <- getPlayerCountValue (PerPlayer 1)
    pure $ toModifiers
      a
      [ HealthModifier healthModifier
      , CanOnlyBeAttackedByAbilityOn (singleton $ CardCode "02219")
      ]
  getModifiersFor _ _ _ = pure []

instance RunMessage BroodOfYogSothoth where
  runMessage msg e@(BroodOfYogSothoth attrs) = case msg of
    Msg.EnemyDamage eid _ (AssetSource aid) _ _ | eid == enemyId attrs -> do
      name <- field AssetName aid
      if name == mkName "Esoteric Formula"
        then BroodOfYogSothoth <$> runMessage msg attrs
        else pure e
    Msg.EnemyDamage eid _ _ _ _ | eid == enemyId attrs -> pure e
    _ -> BroodOfYogSothoth <$> runMessage msg attrs

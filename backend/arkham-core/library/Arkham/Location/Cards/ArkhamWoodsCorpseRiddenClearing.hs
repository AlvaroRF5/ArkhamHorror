module Arkham.Location.Cards.ArkhamWoodsCorpseRiddenClearing where

import Arkham.Prelude

import Arkham.Location.Cards qualified as Cards
  (arkhamWoodsCorpseRiddenClearing)
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Modifier
import Arkham.Target

newtype ArkhamWoodsCorpseRiddenClearing = ArkhamWoodsCorpseRiddenClearing LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

arkhamWoodsCorpseRiddenClearing :: LocationCard ArkhamWoodsCorpseRiddenClearing
arkhamWoodsCorpseRiddenClearing = locationWithRevealedSideConnections
  ArkhamWoodsCorpseRiddenClearing
  Cards.arkhamWoodsCorpseRiddenClearing
  3
  (PerPlayer 1)
  Square
  [Squiggle]
  Droplet
  [Squiggle, Circle]

instance HasModifiersFor ArkhamWoodsCorpseRiddenClearing where
  getModifiersFor _ (EnemyTarget eid) (ArkhamWoodsCorpseRiddenClearing attrs) =
    pure $ toModifiers
      attrs
      [ MaxDamageTaken 1 | eid `elem` locationEnemies attrs ]
  getModifiersFor _ _ _ = pure []

instance RunMessage ArkhamWoodsCorpseRiddenClearing where
  runMessage msg (ArkhamWoodsCorpseRiddenClearing attrs) =
    ArkhamWoodsCorpseRiddenClearing <$> runMessage msg attrs

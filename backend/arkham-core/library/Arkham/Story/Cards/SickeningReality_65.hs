module Arkham.Story.Cards.SickeningReality_65 where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Assets
import Arkham.Asset.Types (Field (..))
import Arkham.Card
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Matcher
import Arkham.Projection
import Arkham.Story.Cards qualified as Cards
import Arkham.Story.Runner

newtype SickeningReality_65 = SickeningReality_65 StoryAttrs
  deriving anyclass (IsStory, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sickeningReality_65 :: StoryCard SickeningReality_65
sickeningReality_65 = story SickeningReality_65 Cards.sickeningReality_65

instance RunMessage SickeningReality_65 where
  runMessage msg s@(SickeningReality_65 attrs) = case msg of
    ResolveStory _ _ story' | story' == toId attrs -> do
      let
        (asset, enemy) =
          (Assets.constanceDumaine, Enemies.constanceDumaine)

      assetId <- fromJustNote "missing" <$> selectOne (assetIs asset)
      enemyCard <- genCard enemy
      lid <-
        fieldMap
          AssetLocation
          (fromJustNote "must be at a location")
          assetId
      iids <- selectList $ InvestigatorAt $ LocationWithId lid
      clues <- field AssetClues assetId
      enemyCreation <- createEnemyAt_ enemyCard lid Nothing
      pushAll $
        [ InvestigatorAssignDamage
          iid
          (toSource attrs)
          DamageAny
          0
          1
        | iid <- iids
        ]
          <> [ RemoveClues (toSource attrs) (toTarget assetId) clues
             , PlaceClues (toSource attrs) (toTarget lid) clues
             , RemoveFromGame (toTarget assetId)
             , enemyCreation
             ]
      pure s
    _ -> SickeningReality_65 <$> runMessage msg attrs

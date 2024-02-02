module Arkham.Location.Cards.EasttownArkhamPoliceStation (
  EasttownArkhamPoliceStation (..),
  easttownArkhamPoliceStation,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Uses
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards (easttownArkhamPoliceStation)
import Arkham.Location.Runner
import Arkham.Matcher

newtype EasttownArkhamPoliceStation = EasttownArkhamPoliceStation LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks, NFData)

easttownArkhamPoliceStation :: LocationCard EasttownArkhamPoliceStation
easttownArkhamPoliceStation = location EasttownArkhamPoliceStation Cards.easttownArkhamPoliceStation 4 (PerPlayer 2)

instance HasAbilities EasttownArkhamPoliceStation where
  getAbilities (EasttownArkhamPoliceStation attrs) =
    withRevealedAbilities attrs
      $ [ playerLimit PerGame
            $ restrictedAbility attrs 1 Here
            $ ActionAbility []
            $ ActionCost 1
        ]

instance RunMessage EasttownArkhamPoliceStation where
  runMessage msg l@(EasttownArkhamPoliceStation attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      ammoAssets <-
        map (Ammo,)
          <$> selectList (AssetControlledBy You <> AssetWithUseType Ammo)
      supplyAssets <-
        map (Supply,)
          <$> selectList (AssetControlledBy You <> AssetWithUseType Supply)
      player <- getPlayer iid
      push
        $ chooseOne
          player
          [ targetLabel assetId [AddUses assetId useType' 2]
          | (useType', assetId) <- ammoAssets <> supplyAssets
          ]
      pure l
    _ -> EasttownArkhamPoliceStation <$> runMessage msg attrs

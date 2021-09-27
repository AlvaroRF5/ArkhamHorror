module Arkham.Types.Asset.Cards.ElderSignAmulet3 where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes

newtype ElderSignAmulet3 = ElderSignAmulet3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

elderSignAmulet3 :: AssetCard ElderSignAmulet3
elderSignAmulet3 =
  accessoryWith ElderSignAmulet3 Cards.elderSignAmulet3 (sanityL ?~ 4)

instance AssetRunner env => RunMessage env ElderSignAmulet3 where
  runMessage msg (ElderSignAmulet3 attrs) =
    ElderSignAmulet3 <$> runMessage msg attrs

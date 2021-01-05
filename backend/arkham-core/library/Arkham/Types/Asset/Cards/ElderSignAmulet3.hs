module Arkham.Types.Asset.Cards.ElderSignAmulet3 where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner

newtype ElderSignAmulet3 = ElderSignAmulet3 Attrs
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

elderSignAmulet3 :: AssetId -> ElderSignAmulet3
elderSignAmulet3 uuid = ElderSignAmulet3 $ (baseAttrs uuid "01095")
  { assetSlots = [AccessorySlot]
  , assetSanity = Just 4
  }

instance HasModifiersFor env ElderSignAmulet3 where
  getModifiersFor = noModifiersFor

instance HasActions env ElderSignAmulet3 where
  getActions i window (ElderSignAmulet3 x) = getActions i window x

instance (AssetRunner env) => RunMessage env ElderSignAmulet3 where
  runMessage msg (ElderSignAmulet3 attrs) =
    ElderSignAmulet3 <$> runMessage msg attrs

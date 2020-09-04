{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Asset.Cards.HardKnocks2 where

import Arkham.Json
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.AssetId
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import qualified Arkham.Types.Window as Fast
import ClassyPrelude

newtype HardKnocks2 = HardKnocks2 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

hardKnocks2 :: AssetId -> HardKnocks2
hardKnocks2 uuid = HardKnocks2 $ baseAttrs uuid "50005"

instance (IsInvestigator investigator) => HasActions env investigator HardKnocks2 where
  getActions i (Fast.WhenSkillTest SkillCombat) (HardKnocks2 Attrs {..})
    | Just (getId () i) == assetInvestigator = pure
      [ UseCardAbility
          (getId () i)
          (AssetSource assetId)
          (AssetSource assetId)
          1
      | resourceCount i > 0
      ]
  getActions i (Fast.WhenSkillTest SkillAgility) (HardKnocks2 Attrs {..})
    | Just (getId () i) == assetInvestigator = pure
      [ UseCardAbility
          (getId () i)
          (AssetSource assetId)
          (AssetSource assetId)
          2
      | resourceCount i > 0
      ]
  getActions _ _ _ = pure []

instance (AssetRunner env) => RunMessage env HardKnocks2 where
  runMessage msg a@(HardKnocks2 attrs@Attrs {..}) = case msg of
    UseCardAbility iid _ (AssetSource aid) 1 | aid == assetId ->
      a <$ unshiftMessages
        [ SpendResources iid 1
        , AddModifier
          SkillTestTarget
          (SkillModifier SkillCombat 1 (AssetSource aid))
        ]
    UseCardAbility iid _ (AssetSource aid) 2 | aid == assetId ->
      a <$ unshiftMessages
        [ SpendResources iid 1
        , AddModifier
          SkillTestTarget
          (SkillModifier SkillAgility 1 (AssetSource aid))
        ]
    _ -> HardKnocks2 <$> runMessage msg attrs

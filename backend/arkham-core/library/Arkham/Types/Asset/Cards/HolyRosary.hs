module Arkham.Types.Asset.Cards.HolyRosary where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype HolyRosary = HolyRosary AssetAttrs
  deriving anyclass (IsAsset, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

holyRosary :: AssetCard HolyRosary
holyRosary = accessoryWith HolyRosary Cards.holyRosary (sanityL ?~ 2)

instance HasModifiersFor env  HolyRosary where
  getModifiersFor _ (InvestigatorTarget iid) (HolyRosary a) =
    pure [ toModifier a (SkillModifier SkillWillpower 1) | ownedBy a iid ]
  getModifiersFor _ _ _ = pure []

instance AssetRunner env => RunMessage env HolyRosary where
  runMessage msg (HolyRosary attrs) = HolyRosary <$> runMessage msg attrs

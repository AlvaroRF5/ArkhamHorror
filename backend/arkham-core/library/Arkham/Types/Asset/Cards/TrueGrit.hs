module Arkham.Types.Asset.Cards.TrueGrit
  ( trueGrit
  , TrueGrit(..)
  ) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.Id
import Arkham.Types.Modifier
import Arkham.Types.Source

newtype TrueGrit = TrueGrit AssetAttrs
  deriving anyclass (IsAsset, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

trueGrit :: AssetCard TrueGrit
trueGrit = assetWith TrueGrit Cards.trueGrit (healthL ?~ 3)

instance (HasId LocationId env InvestigatorId) => HasModifiersFor env TrueGrit where
  getModifiersFor (InvestigatorSource iid) target (TrueGrit a)
    | isTarget a target = do
      locationId <- getId @LocationId iid
      assetLocationId <- getId @LocationId
        $ fromJustNote "unowned" (assetInvestigator a)
      pure
        [ toModifier a CanBeAssignedDamage
        | locationId == assetLocationId && Just iid /= assetInvestigator a
        ]
  getModifiersFor _ _ _ = pure []

instance AssetRunner env => RunMessage env TrueGrit where
  runMessage msg (TrueGrit attrs) = TrueGrit <$> runMessage msg attrs

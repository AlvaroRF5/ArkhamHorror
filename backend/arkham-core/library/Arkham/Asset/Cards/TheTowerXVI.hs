module Arkham.Asset.Cards.TheTowerXVI
  ( theTowerXVI
  , TheTowerXVI(..)
  )
where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Asset.Runner
import Arkham.Matcher
import Arkham.Target
import Arkham.Placement

newtype TheTowerXVI = TheTowerXVI AssetAttrs
  deriving anyclass (IsAsset, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theTowerXVI :: AssetCard TheTowerXVI
theTowerXVI =
  asset TheTowerXVI Cards.theTowerXVI

instance HasModifiersFor TheTowerXVI where
  getModifiersFor (InvestigatorTarget _) (TheTowerXVI attrs) | assetPlacement attrs == Unplaced =
    pure $ toModifiers attrs [CannotCommitCards AnyCard]
  getModifiersFor _ _ = pure []

instance RunMessage TheTowerXVI where
  runMessage msg (TheTowerXVI attrs) = TheTowerXVI <$> runMessage msg attrs

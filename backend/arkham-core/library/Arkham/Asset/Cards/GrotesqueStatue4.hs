module Arkham.Asset.Cards.GrotesqueStatue4
  ( GrotesqueStatue4(..)
  , grotesqueStatue4
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.ChaosBagStepState
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Timing qualified as Timing
import Arkham.Window (Window(..))
import Arkham.Window qualified as Window

newtype GrotesqueStatue4 = GrotesqueStatue4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

grotesqueStatue4 :: AssetCard GrotesqueStatue4
grotesqueStatue4 =
  assetWith GrotesqueStatue4 Cards.grotesqueStatue4 (discardWhenNoUsesL .~ True)

instance HasAbilities GrotesqueStatue4 where
  getAbilities (GrotesqueStatue4 x) =
    [ restrictedAbility
        x
        1
        OwnsThis
        (ReactionAbility (WouldRevealChaosToken Timing.When You)
        $ UseCost (AssetWithId $ toId x) Charge 1
        )
    ]

instance RunMessage GrotesqueStatue4 where
  runMessage msg a@(GrotesqueStatue4 attrs) = case msg of
    UseCardAbility iid source [Window Timing.When (Window.WouldRevealChaosToken drawSource _)] 1 _
      | isSource attrs source
      -> a <$ push
        (ReplaceCurrentDraw drawSource iid
        $ Choose 1 [Undecided Draw, Undecided Draw] []
        )
    _ -> GrotesqueStatue4 <$> runMessage msg attrs

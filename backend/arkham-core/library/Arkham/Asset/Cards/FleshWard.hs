module Arkham.Asset.Cards.FleshWard (
  fleshWard,
  FleshWard (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Matcher
import Arkham.Timing qualified as Timing
import Arkham.Window (Window (..), mkWindow)
import Arkham.Window qualified as Window

newtype FleshWard = FleshWard AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fleshWard :: AssetCard FleshWard
fleshWard = assetWith FleshWard Cards.fleshWard ((healthL ?~ 1) . (sanityL ?~ 1))

instance HasAbilities FleshWard where
  getAbilities (FleshWard a) =
    [ restrictedAbility a 1 ControlsThis
        $ ReactionAbility
          (DealtDamageOrHorror Timing.When (SourceIsCancelable $ SourceIsEnemyAttack AnyEnemy) You)
        $ exhaust a
          <> UseCost (AssetWithId $ toId a) Charge 1
    ]

dealtDamage :: [Window] -> Bool
dealtDamage [] = False
dealtDamage ((windowType -> Window.WouldTakeDamageOrHorror _ _ n _) : _) = n > 0
dealtDamage (_ : xs) = dealtDamage xs

dealtHorror :: [Window] -> Bool
dealtHorror [] = False
dealtHorror ((windowType -> Window.WouldTakeDamageOrHorror _ _ _ n) : _) = n > 0
dealtHorror (_ : xs) = dealtDamage xs

instance RunMessage FleshWard where
  runMessage msg a@(FleshWard attrs) = case msg of
    UseCardAbility iid source 1 windows' _ | isSource attrs source -> do
      ignoreWindow <-
        checkWindows
          [mkWindow Timing.After (Window.CancelledOrIgnoredCardOrGameEffect $ toAbilitySource attrs 1)]
      push $
        chooseOrRunOne iid $
          [ Label "Cancel 1 damage" [CancelDamage iid 1, ignoreWindow]
          | dealtDamage windows'
          ]
            <> [ Label "Cancel 1 horror" [CancelHorror iid 1, ignoreWindow]
               | dealtHorror windows'
               ]
      pure a
    _ -> FleshWard <$> runMessage msg attrs

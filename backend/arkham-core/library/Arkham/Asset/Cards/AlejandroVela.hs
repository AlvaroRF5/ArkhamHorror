module Arkham.Asset.Cards.AlejandroVela
  ( alejandroVela
  , AlejandroVela(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Helpers.SkillTest
import Arkham.Matcher
import Arkham.Target
import Arkham.Trait

newtype AlejandroVela = AlejandroVela AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

alejandroVela :: AssetCard AlejandroVela
alejandroVela = ally AlejandroVela Cards.alejandroVela (2, 2)

instance HasModifiersFor AlejandroVela where
  getModifiersFor _ (InvestigatorTarget iid) (AlejandroVela a)
    | controlledBy a iid = do
      mTarget <- getSkillTestTarget
      mAction <- getSkillTestAction
      case (mTarget, mAction) of
        (Just (LocationTarget lid), Just Action.Investigate) -> do
          isAncient <- lid <=~> LocationWithTrait Ancient
          pure $ toModifiers a [ AnySkillValue 1 | isAncient ]
        _ -> pure []
  getModifiersFor _ _ _ = pure []

instance HasAbilities AlejandroVela where
  getAbilities (AlejandroVela a) =
    [ restrictedAbility
          a
          1
          (ControlsThis <> OnLocation (LocationWithTrait Ancient))
        $ ActionAbility Nothing
        $ ActionCost 1
        <> ExhaustCost (toTarget a)
    ]

instance RunMessage AlejandroVela where
  runMessage msg (AlejandroVela attrs) = AlejandroVela <$> runMessage msg attrs

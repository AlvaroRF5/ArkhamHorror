module Arkham.Asset.Cards.Burglary (
  Burglary (..),
  burglary,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Investigator.Types (Field (..))
import Arkham.Location.Types (Field (..))
import Arkham.Projection

newtype Burglary = Burglary AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

burglary :: AssetCard Burglary
burglary = asset Burglary Cards.burglary

instance HasAbilities Burglary where
  getAbilities (Burglary a) =
    [ restrictedAbility a 1 ControlsThis
        $ ActionAbility (Just Action.Investigate)
        $ Costs [ActionCost 1, exhaust a]
    ]

instance RunMessage Burglary where
  runMessage msg a@(Burglary attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      lid <- fieldJust InvestigatorLocation iid
      skillType <- field LocationInvestigateSkill lid
      push $ Investigate iid lid (toSource attrs) (Just $ toTarget attrs) skillType False
      pure a
    Successful (Action.Investigate, _) iid _ (isTarget attrs -> True) _ -> do
      push $ TakeResources iid 3 (toAbilitySource attrs 1) False
      pure a
    _ -> Burglary <$> runMessage msg attrs

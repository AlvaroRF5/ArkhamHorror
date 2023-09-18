module Arkham.Asset.Cards.AncientStoneTransientThoughts4 (
  ancientStoneTransientThoughts4,
  AncientStoneTransientThoughts4 (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.CampaignLogKey
import Arkham.Matcher hiding (NonAttackDamageEffect)
import Arkham.Movement

newtype AncientStoneTransientThoughts4 = AncientStoneTransientThoughts4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ancientStoneTransientThoughts4
  :: AssetCard AncientStoneTransientThoughts4
ancientStoneTransientThoughts4 = asset AncientStoneTransientThoughts4 Cards.ancientStoneTransientThoughts4

instance HasAbilities AncientStoneTransientThoughts4 where
  getAbilities (AncientStoneTransientThoughts4 a) =
    [ restrictedAbility
        a
        1
        (ControlsThis <> InvestigatorExists (You <> InvestigatorCanMove))
        $ ReactionAbility
          (DrawsCards #when You AnyValue)
          (DynamicUseCost (AssetWithId $ toId a) Secret DrawnCardsValue)
    ]

getMoves :: Payment -> Int
getMoves (UsesPayment n) = n
getMoves (Payments ps) = sum $ map getMoves ps
getMoves _ = 0

instance RunMessage AncientStoneTransientThoughts4 where
  runMessage msg a@(AncientStoneTransientThoughts4 attrs) = case msg of
    InvestigatorPlayedAsset _ aid | aid == toId attrs -> do
      n <- getRecordCount YouHaveIdentifiedTheStone
      AncientStoneTransientThoughts4 <$> runMessage msg (attrs {assetUses = Uses Secret n})
    UseCardAbility iid (isSource attrs -> True) 1 ws p@(getMoves -> n) -> do
      pushAll $ replicate n $ UseCardAbilityStep iid (toSource attrs) 1 ws p 1
      pure a
    UseCardAbilityStep iid (isSource attrs -> True) 1 _ _ 1 -> do
      targets <- selectList $ AccessibleFrom $ locationWithInvestigator iid
      pushWhen (notNull targets)
        $ chooseOne iid
        $ targetLabels targets (only . Move . move (toAbilitySource attrs 1) iid)
      pure a
    _ -> AncientStoneTransientThoughts4 <$> runMessage msg attrs

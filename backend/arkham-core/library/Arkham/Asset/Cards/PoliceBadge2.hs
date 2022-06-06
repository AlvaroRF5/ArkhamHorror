module Arkham.Asset.Cards.PoliceBadge2
  ( PoliceBadge2(..)
  , policeBadge2
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target

newtype PoliceBadge2 = PoliceBadge2 AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

policeBadge2 :: AssetCard PoliceBadge2
policeBadge2 = asset PoliceBadge2 Cards.policeBadge2

instance HasModifiersFor env PoliceBadge2 where
  getModifiersFor _ (InvestigatorTarget iid) (PoliceBadge2 a) =
    pure [ toModifier a (SkillModifier SkillWillpower 1) | controlledBy a iid ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities PoliceBadge2 where
  getAbilities (PoliceBadge2 a) =
    [restrictedAbility a 1 criteria $ FastAbility $ DiscardCost (toTarget a)]
   where
    criteria = OwnsThis
      <> InvestigatorExists (TurnInvestigator <> InvestigatorAt YourLocation)

instance RunMessage PoliceBadge2 where
  runMessage msg a@(PoliceBadge2 attrs) = case msg of
    InDiscard _ (UseCardAbility _ source _ 1 _) | isSource attrs source ->
      selectOne TurnInvestigator >>= \case
        Nothing -> error "must exist"
        Just iid -> a <$ push (GainActions iid source 2)
    _ -> PoliceBadge2 <$> runMessage msg attrs

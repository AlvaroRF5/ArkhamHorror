module Arkham.Asset.Cards.PhysicalTraining4
  ( physicalTraining4
  , PhysicalTraining4(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.SkillType
import Arkham.Target

newtype PhysicalTraining4 = PhysicalTraining4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

physicalTraining4 :: AssetCard PhysicalTraining4
physicalTraining4 = asset PhysicalTraining4 Cards.physicalTraining4

instance HasAbilities PhysicalTraining4 where
  getAbilities (PhysicalTraining4 a) =
    [ restrictedAbility a 1 (ControlsThis <> DuringSkillTest AnySkillTest)
        $ FastAbility
        $ OrCost [ResourceCost 1, UseCost (AssetWithId $ toId a) Resource 1]
    ]

instance RunMessage PhysicalTraining4 where
  runMessage msg a@(PhysicalTraining4 attrs) = case msg of
    BeginRound -> pure . PhysicalTraining4 $ attrs & usesL .~ Uses Resource 2
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ chooseOne
        iid
        [ Label
          "Choose Willpower"
          [ skillTestModifier
              attrs
              (InvestigatorTarget iid)
              (SkillModifier SkillWillpower 1)
          ]
        , Label
          "Choose Combat"
          [ skillTestModifier
              attrs
              (InvestigatorTarget iid)
              (SkillModifier SkillCombat 1)
          ]
        ]
      pure a
    _ -> PhysicalTraining4 <$> runMessage msg attrs

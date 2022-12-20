module Arkham.Asset.Cards.Thermos
  ( thermos
  , Thermos(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Investigator.Types ( Field (..) )
import Arkham.Matcher
import Arkham.Projection
import Arkham.Target

newtype Thermos = Thermos AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

thermos :: AssetCard Thermos
thermos = asset Thermos Cards.thermos

instance HasAbilities Thermos where
  getAbilities (Thermos a) =
    [ withTooltip
        "Heal 1 damage from an investigator at your location (2 damage instead if he or she has 2 or more physical trauma)."
      $ restrictedAbility
          a
          1
          (ControlsThis <> InvestigatorExists
            (InvestigatorAt YourLocation <> InvestigatorWithAnyDamage)
          )
      $ ActionAbility Nothing
      $ ActionCost 1
      <> ExhaustCost (toTarget a)
    , withTooltip
        "Heal 1 horror from an investigator at your location (2 horror instead if he or she has 2 or more mental trauma)."
      $ restrictedAbility
          a
          2
          (ControlsThis <> InvestigatorExists
            (InvestigatorAt YourLocation <> InvestigatorWithAnyHorror)
          )
      $ ActionAbility Nothing
      $ ActionCost 1
      <> ExhaustCost (toTarget a)
    ]

instance RunMessage Thermos where
  runMessage msg a@(Thermos attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 windows' payment -> do
      targets <-
        selectListMap InvestigatorTarget
        $ colocatedWith iid
        <> InvestigatorWithAnyDamage
      push $ chooseOrRunOne
        iid
        [ TargetLabel
            target
            [ UseCardAbilityChoiceTarget
                iid
                (toSource attrs)
                1
                target
                windows'
                payment
            ]
        | target <- targets
        ]
      pure a
    UseCardAbilityChoiceTarget _ (isSource attrs -> True) 1 (InvestigatorTarget iid') _ _
      -> do
        trauma <- field InvestigatorPhysicalTrauma iid'
        push $ HealDamage
          (InvestigatorTarget iid')
          (toSource attrs)
          (if trauma >= 2 then 2 else 1)
        pure a
    UseCardAbility iid (isSource attrs -> True) 2 windows' payment -> do
      targets <-
        selectListMap InvestigatorTarget
        $ colocatedWith iid
        <> InvestigatorWithAnyHorror
      push $ chooseOrRunOne
        iid
        [ TargetLabel
            target
            [ UseCardAbilityChoiceTarget
                iid
                (toSource attrs)
                2
                target
                windows'
                payment
            ]
        | target <- targets
        ]
      pure a
    UseCardAbilityChoiceTarget _ (isSource attrs -> True) 2 (InvestigatorTarget iid') _ _
      -> do
        trauma <- field InvestigatorMentalTrauma iid'
        push $ HealHorror
          (InvestigatorTarget iid')
          (toSource attrs)
          (if trauma >= 2 then 2 else 1)
        pure a
    _ -> Thermos <$> runMessage msg attrs

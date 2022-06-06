module Arkham.Asset.Cards.HiredMuscle1
  ( hiredMuscle1
  , HiredMuscle1(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Modifier
import Arkham.Phase
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype HiredMuscle1 = HiredMuscle1 AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

hiredMuscle1 :: AssetCard HiredMuscle1
hiredMuscle1 = ally HiredMuscle1 Cards.hiredMuscle1 (3, 1)

instance HasAbilities HiredMuscle1 where
  getAbilities (HiredMuscle1 x) =
    [ restrictedAbility x 1 OwnsThis
      $ ForcedAbility
      $ PhaseEnds Timing.When
      $ PhaseIs UpkeepPhase
    ]

instance HasModifiersFor env HiredMuscle1 where
  getModifiersFor _ (InvestigatorTarget iid) (HiredMuscle1 a) =
    pure [ toModifier a (SkillModifier SkillCombat 1) | controlledBy a iid ]
  getModifiersFor _ _ _ = pure []

instance RunMessage HiredMuscle1 where
  runMessage msg a@(HiredMuscle1 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ push
      (chooseOne
        iid
        [ Label "Pay 1 Resource to Hired Muscle" [SpendResources iid 1]
        , Label "Discard Hired Muscle" [Discard $ toTarget attrs]
        ]
      )
    _ -> HiredMuscle1 <$> runMessage msg attrs

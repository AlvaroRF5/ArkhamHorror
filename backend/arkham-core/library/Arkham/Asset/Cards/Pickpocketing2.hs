module Arkham.Asset.Cards.Pickpocketing2
  ( Pickpocketing2(..)
  , pickpocketing2
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Matcher
import Arkham.Matcher qualified as Matcher
import Arkham.SkillTest
import Arkham.SkillTestResult
import Arkham.Timing qualified as Timing

newtype Pickpocketing2 = Pickpocketing2 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

pickpocketing2 :: AssetCard Pickpocketing2
pickpocketing2 = asset Pickpocketing2 Cards.pickpocketing2

instance HasAbilities Pickpocketing2 where
  getAbilities (Pickpocketing2 a) =
    [ restrictedAbility a 1 ControlsThis $ ReactionAbility
        (Matcher.EnemyEvaded Timing.After You AnyEnemy)
        (ExhaustCost $ toTarget a)
    ]

instance RunMessage Pickpocketing2 where
  runMessage msg a@(Pickpocketing2 attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      mskillTest <- getSkillTest
      drawing <- drawCards iid attrs 1
      case skillTestResult <$> mskillTest of
        Just (SucceededBy _ n) | n >= 2 -> do
          pushAll [drawing, TakeResources iid 1 (toAbilitySource attrs 1) False]
        _ -> push $ chooseOne
          iid
          [ Label "Draw 1 card" [drawing]
          , Label "Gain 1 resource" [TakeResources iid 1 (toAbilitySource attrs 1) False]
          ]
      pure a
    _ -> Pickpocketing2 <$> runMessage msg attrs

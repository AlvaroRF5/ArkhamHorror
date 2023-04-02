module Arkham.Asset.Cards.TennesseeSourMashSurvivor3
  ( tennesseeSourMashSurvivor3
  , TennesseeSourMashSurvivor3(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher hiding (EnemyEvaded)
import Arkham.SkillType

newtype TennesseeSourMashSurvivor3 = TennesseeSourMashSurvivor3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

tennesseeSourMashSurvivor3 :: AssetCard TennesseeSourMashSurvivor3
tennesseeSourMashSurvivor3 =
  asset TennesseeSourMashSurvivor3 Cards.tennesseeSourMashSurvivor3

instance HasAbilities TennesseeSourMashSurvivor3 where
  getAbilities (TennesseeSourMashSurvivor3 a) =
    [ restrictedAbility
        a
        1
        (ControlsThis <> DuringSkillTest (SkillTestOnTreachery AnyTreachery))
      $ FastAbility
      $ ExhaustCost (toTarget a)
      <> UseCost (AssetWithId $ toId a) Supply 1
    , restrictedAbility a 2 ControlsThis
      $ ActionAbility (Just Action.Fight)
      $ ActionCost 1
      <> DiscardCost FromPlay (toTarget a)
    ]

instance RunMessage TennesseeSourMashSurvivor3 where
  runMessage msg a@(TennesseeSourMashSurvivor3 attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $ skillTestModifier attrs iid (SkillModifier SkillWillpower 2)
      pure a
    InDiscard _ (UseCardAbility iid (isSource attrs -> True) 2 _ _) -> do
      pushAll
        $ [ skillTestModifier
            attrs
            (InvestigatorTarget iid)
            (SkillModifier SkillCombat 3)
          , ChooseFightEnemy
            iid
            (toSource attrs)
            Nothing
            SkillCombat
            mempty
            False
          ]
      pure a
    InDiscard _ (PassedSkillTest iid _ (isSource attrs -> True) SkillTestInitiatorTarget{} _ _)
      -> do
        mTarget <- getSkillTestTarget
        case mTarget of
          Just (EnemyTarget eid) -> do
            nonElite <- eid <=~> NonEliteEnemy
            when nonElite $ push $ EnemyEvaded iid eid
          _ -> error "impossible"
        pure a
    _ -> TennesseeSourMashSurvivor3 <$> runMessage msg attrs

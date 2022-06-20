module Arkham.Asset.Cards.Suggestion4
  ( suggestion4
  , Suggestion4(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Attrs
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype Suggestion4 = Suggestion4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

suggestion4 :: AssetCard Suggestion4
suggestion4 = asset Suggestion4 Cards.suggestion4

instance HasAbilities Suggestion4 where
  getAbilities (Suggestion4 a) =
    [ restrictedAbility a 1 OwnsThis
      $ ActionAbility (Just Action.Evade)
      $ ActionCost 1
      <> ExhaustCost (toTarget a)
    , restrictedAbility a 2 OwnsThis
      $ ReactionAbility (EnemyWouldAttack Timing.When You AnyEnemyAttack AnyEnemy)
      $ UseCost (AssetWithId $ toId a) Charge 1
    ]

instance RunMessage Suggestion4 where
  runMessage msg a@(Suggestion4 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifier
        source
        (InvestigatorTarget iid)
        (AddSkillValue SkillWillpower)
      , ChooseEvadeEnemy iid source Nothing SkillAgility AnyEnemy False
      ]
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source && n < 2 -> a
      <$ push (SpendUses (toTarget attrs) Charge 1)
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> a <$ push (SpendUses (toTarget attrs) Charge 1)
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      a <$ push (CancelNext AttackMessage)
    _ -> Suggestion4 <$> runMessage msg attrs

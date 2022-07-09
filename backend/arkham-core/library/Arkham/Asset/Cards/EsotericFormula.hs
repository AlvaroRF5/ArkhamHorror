module Arkham.Asset.Cards.EsotericFormula
  ( esotericFormula
  , EsotericFormula(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Enemy.Attrs ( Field(..) )
import Arkham.Matcher
import Arkham.Projection
import Arkham.SkillType
import Arkham.SkillTest
import Arkham.Source
import Arkham.Target
import Arkham.Trait

newtype EsotericFormula = EsotericFormula AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

esotericFormula :: AssetCard EsotericFormula
esotericFormula = asset EsotericFormula Cards.esotericFormula

instance HasAbilities EsotericFormula where
  getAbilities (EsotericFormula x) =
    [ restrictedAbility
        x
        1
        (ControlsThis <> EnemyCriteria
          (EnemyExists $ CanFightEnemy <> EnemyWithTrait Abomination)
        )
        (ActionAbility (Just Action.Fight) (ActionCost 1))
    ]

instance HasModifiersFor EsotericFormula where
  getModifiersFor (SkillTestSource iid' _ source (Just Action.Fight)) (InvestigatorTarget iid) (EsotericFormula attrs)
    | controlledBy attrs iid && isSource attrs source && iid' == iid
    = do
      skillTestTarget <- fromJustNote "not a skilltest" <$> getSkillTestTarget
      case skillTestTarget of
        EnemyTarget eid -> do
          clueCount <- field EnemyClues eid
          pure $ toModifiers attrs [SkillModifier SkillWillpower (clueCount * 2)]
        _ -> error "Invalid target"
  getModifiersFor _ _ _ = pure []

instance RunMessage EsotericFormula where
  runMessage msg a@(EsotericFormula attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ push
      (ChooseFightEnemy
        iid
        source
        Nothing
        SkillWillpower
        (EnemyWithTrait Abomination)
        False
      )
    _ -> EsotericFormula <$> runMessage msg attrs

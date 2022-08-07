module Arkham.Asset.Cards.GildedVolto
  ( gildedVolto
  , GildedVolto(..)
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
import Arkham.Timing qualified as Timing

newtype GildedVolto = GildedVolto AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

gildedVolto :: AssetCard GildedVolto
gildedVolto = asset GildedVolto Cards.gildedVolto

instance HasAbilities GildedVolto where
  getAbilities (GildedVolto a) =
    [ restrictedAbility a 1 ControlsThis
      $ ReactionAbility
          (AssetEntersPlay Timing.After $ AssetWithId $ toId a)
          Free
    , restrictedAbility a 2 ControlsThis $ ReactionAbility
      (InitiatedSkillTest Timing.When You (NotSkillType SkillAgility) AnyValue)
      (DiscardCost $ toTarget a)
    ]

instance RunMessage GildedVolto where
  runMessage msg a@(GildedVolto attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ CreateEffect "82026" Nothing source (InvestigatorTarget iid)
      pure a
    UseCardAbility _ source _ 2 _
      | isSource attrs source
      -> do
        replaceMessageMatching
          (\case
            BeginSkillTestAfterFast{} -> True
            Ask _ (ChooseOne (SkillLabel _ (BeginSkillTestAfterFast{} : _) : _))
              -> True
            _ -> False
          )
          (\case
            BeginSkillTestAfterFast iid' source' target' maction' _ difficulty'
              -> [ BeginSkillTest
                     iid'
                     source'
                     target'
                     maction'
                     SkillAgility
                     difficulty'
                 ]
            Ask _ (ChooseOne (SkillLabel _ (BeginSkillTestAfterFast iid' source' target' maction' _ difficulty' : _) : _))
              -> [ BeginSkillTest
                     iid'
                     source'
                     target'
                     maction'
                     SkillAgility
                     difficulty'
                 ]
            _ -> error "invalid match"
          )
        pure a
    _ -> GildedVolto <$> runMessage msg attrs

module Arkham.Types.Asset.Cards.DigDeep
  ( DigDeep(..)
  , digDeep
  ) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype DigDeep = DigDeep AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

digDeep :: AssetCard DigDeep
digDeep = asset DigDeep Cards.digDeep

instance HasAbilities DigDeep where
  getAbilities (DigDeep a) =
    [ restrictedAbility a idx (OwnsThis <> DuringSkillTest AnySkillTest)
      $ FastAbility
      $ ResourceCost 1
    | idx <- [1, 2]
    ]

instance (AssetRunner env) => RunMessage env DigDeep where
  runMessage msg a@(DigDeep attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ push
      (skillTestModifier
        attrs
        (InvestigatorTarget iid)
        (SkillModifier SkillWillpower 1)
      )
    UseCardAbility iid source _ 2 _ | isSource attrs source -> a <$ push
      (skillTestModifier
        attrs
        (InvestigatorTarget iid)
        (SkillModifier SkillAgility 1)
      )
    _ -> DigDeep <$> runMessage msg attrs

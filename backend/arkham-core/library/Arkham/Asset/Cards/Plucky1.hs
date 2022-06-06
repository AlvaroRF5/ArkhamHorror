module Arkham.Asset.Cards.Plucky1
  ( plucky1
  , Plucky1(..)
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

newtype Plucky1 = Plucky1 AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

plucky1 :: AssetCard Plucky1
plucky1 = assetWith Plucky1 Cards.plucky1 (sanityL ?~ 1)

instance HasAbilities Plucky1 where
  getAbilities (Plucky1 x) =
    [ restrictedAbility x idx (OwnsThis <> DuringSkillTest AnySkillTest)
        $ FastAbility
        $ ResourceCost 1
    | idx <- [1, 2]
    ]

instance HasModifiersFor Plucky1 where
  getModifiersFor _ (AssetTarget aid) (Plucky1 attrs) | toId attrs == aid =
    pure $ toModifiers attrs [NonDirectHorrorMustBeAssignToThisFirst]
  getModifiersFor _ _ _ = pure []

instance RunMessage Plucky1 where
  runMessage msg a@(Plucky1 attrs) = case msg of
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
        (SkillModifier SkillIntellect 1)
      )
    _ -> Plucky1 <$> runMessage msg attrs

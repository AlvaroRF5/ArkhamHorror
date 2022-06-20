module Arkham.Asset.Cards.Grounded1
  ( grounded1
  , Grounded1(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Target
import Arkham.Trait

newtype Grounded1 = Grounded1 AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

grounded1 :: AssetCard Grounded1
grounded1 = assetWith Grounded1 Cards.grounded1 (sanityL ?~ 1)

instance HasAbilities Grounded1 where
  getAbilities (Grounded1 x) =
    [ restrictedAbility
          x
          1
          (OwnsThis <> DuringSkillTest
            (SkillTestSourceMatches $ SourceWithTrait Spell)
          )
        $ FastAbility
        $ ResourceCost 1
    ]

instance HasModifiersFor Grounded1 where
  getModifiersFor _ (AssetTarget aid) (Grounded1 attrs) | toId attrs == aid =
    pure $ toModifiers attrs [NonDirectHorrorMustBeAssignToThisFirst]
  getModifiersFor _ _ _ = pure []

instance RunMessage Grounded1 where
  runMessage msg a@(Grounded1 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push
        (skillTestModifier attrs (InvestigatorTarget iid) (AnySkillValue 1))
    _ -> Grounded1 <$> runMessage msg attrs

module Arkham.Asset.Cards.DavidRenfield
  ( davidRenfield
  , DavidRenfield(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.SkillType
import Arkham.Target

newtype DavidRenfield = DavidRenfield AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

davidRenfield :: AssetCard DavidRenfield
davidRenfield = ally DavidRenfield Cards.davidRenfield (2, 1)

instance HasModifiersFor DavidRenfield where
  getModifiersFor (InvestigatorTarget iid) (DavidRenfield attrs)
    | attrs `controlledBy` iid = pure $ toModifiers
      attrs
      [ SkillModifier SkillWillpower 1 | assetDoom attrs > 0 ]
  getModifiersFor _ _ = pure []

instance HasAbilities DavidRenfield where
  getAbilities (DavidRenfield a) =
    [ restrictedAbility a 1 ControlsThis $ FastAbility $ ExhaustCost $ toTarget
        a
    ]

instance RunMessage DavidRenfield where
  runMessage msg a@(DavidRenfield attrs) = case msg of
    UseCardAbility iid source 1 windows' p | isSource attrs source -> do
      let
        resolveAbility =
          UseCardAbilityChoice iid source 1 NoAbilityMetadata windows' p
      push $ chooseOne
        iid
        [ Label
          "Place doom on David Renfield"
          [PlaceDoom (toTarget attrs) 1, resolveAbility]
        , Label "Do not place doom on David Renfield" [resolveAbility]
        ]
      pure a
    UseCardAbilityChoice iid source 1 _ _ _ | isSource attrs source ->
      a <$ push (TakeResources iid (assetDoom attrs) False)
    _ -> DavidRenfield <$> runMessage msg attrs

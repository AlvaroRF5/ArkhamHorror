module Arkham.Asset.Cards.GravediggersShovel (
  gravediggersShovel,
  GravediggersShovel (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Matcher
import Arkham.SkillType

newtype GravediggersShovel = GravediggersShovel AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

gravediggersShovel :: AssetCard GravediggersShovel
gravediggersShovel = asset GravediggersShovel Cards.gravediggersShovel

instance HasAbilities GravediggersShovel where
  getAbilities (GravediggersShovel x) =
    [ restrictedAbility x 1 ControlsThis $
        ActionAbility (Just Action.Fight) (ActionCost 1)
    , restrictedAbility
        x
        2
        ( ControlsThis
            <> InvestigatorExists
              (You <> InvestigatorCanDiscoverCluesAt YourLocation)
        )
        $ ActionAbility Nothing
        $ Costs [ActionCost 1, DiscardCost FromPlay (toTarget x)]
    ]

instance RunMessage GravediggersShovel where
  runMessage msg a@(GravediggersShovel attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      pushAll
        [ skillTestModifier attrs iid (SkillModifier SkillCombat 2)
        , ChooseFightEnemy iid source Nothing SkillCombat mempty False
        ]
      pure a
    InDiscard _ (UseCardAbility iid source 2 _ _) | isSource attrs source -> do
      a <$ push (InvestigatorDiscoverCluesAtTheirLocation iid (toAbilitySource attrs 2) 1 Nothing)
    _ -> GravediggersShovel <$> runMessage msg attrs

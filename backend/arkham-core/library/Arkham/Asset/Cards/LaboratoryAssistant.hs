module Arkham.Asset.Cards.LaboratoryAssistant (
  LaboratoryAssistant (..),
  laboratoryAssistant,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Matcher
import Arkham.Timing qualified as Timing

newtype LaboratoryAssistant = LaboratoryAssistant AssetAttrs
  deriving anyclass (IsAsset)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

laboratoryAssistant :: AssetCard LaboratoryAssistant
laboratoryAssistant = ally LaboratoryAssistant Cards.laboratoryAssistant (1, 2)

instance HasModifiersFor LaboratoryAssistant where
  getModifiersFor (InvestigatorTarget iid) (LaboratoryAssistant attrs) | controlledBy attrs iid = do
    pure $ toModifiers attrs [HandSize 2]
  getModifiersFor _ _ = pure []

instance HasAbilities LaboratoryAssistant where
  getAbilities (LaboratoryAssistant x) =
    [ restrictedAbility x 1 ControlsThis
        $ ReactionAbility
          (AssetEntersPlay Timing.When (AssetWithId $ toId x))
          Free
    ]

instance RunMessage LaboratoryAssistant where
  runMessage msg a@(LaboratoryAssistant attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      pushM $ drawCards iid (toAbilitySource attrs 1) 2
      pure a
    _ -> LaboratoryAssistant <$> runMessage msg attrs

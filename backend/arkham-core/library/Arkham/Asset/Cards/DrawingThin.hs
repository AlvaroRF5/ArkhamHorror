module Arkham.Asset.Cards.DrawingThin
  ( drawingThin
  , DrawingThin(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.Matcher
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype DrawingThin = DrawingThin AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drawingThin :: AssetCard DrawingThin
drawingThin = asset DrawingThin Cards.drawingThin

instance HasAbilities DrawingThin where
  getAbilities (DrawingThin a) =
    [ restrictedAbility a 1 ControlsThis
        $ ReactionAbility
            (InitiatedSkillTest Timing.When You AnySkillType AnyValue)
        $ ExhaustCost (toTarget a)
    ]

instance RunMessage DrawingThin where
  runMessage msg a@(DrawingThin attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ CreateWindowModifierEffect
        EffectSkillTestWindow
        (EffectModifiers $ toModifiers attrs [Difficulty 2])
        source
        SkillTestTarget
      , chooseOne
        iid
        [ Label "Take 2 resources" [TakeResources iid 2 False]
        , Label "Draw 1 card" [DrawCards iid 1 False]
        ]
      ]
    _ -> DrawingThin <$> runMessage msg attrs

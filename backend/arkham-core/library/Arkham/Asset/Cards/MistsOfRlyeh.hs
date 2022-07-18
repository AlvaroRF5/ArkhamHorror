module Arkham.Asset.Cards.MistsOfRlyeh
  ( mistsOfRlyeh
  , MistsOfRlyeh(..)
  , mistsOfRlyehEffect
  , MistsOfRlyehEffect(..)
  ) where

import Arkham.Prelude

import Arkham.SkillTestResult
import Arkham.SkillTest.Base
import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Effect.Attrs
import Arkham.Effect.Runner ()
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Matcher hiding (MoveAction)
import Arkham.SkillType
import Arkham.Target
import Arkham.Token

newtype MistsOfRlyeh = MistsOfRlyeh AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

mistsOfRlyeh :: AssetCard MistsOfRlyeh
mistsOfRlyeh = asset MistsOfRlyeh Cards.mistsOfRlyeh

instance HasAbilities MistsOfRlyeh where
  getAbilities (MistsOfRlyeh a) =
    [ restrictedAbility a 1 ControlsThis $ ActionAbility
        (Just Action.Evade)
        (Costs [ActionCost 1, UseCost (AssetWithId $ toId a) Charge 1])
    ]

instance RunMessage MistsOfRlyeh where
  runMessage msg a@(MistsOfRlyeh attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      a <$ pushAll
        [ CreateEffect "04029" Nothing source (InvestigatorTarget iid)
        , ChooseEvadeEnemy iid source Nothing SkillWillpower AnyEnemy False
        ]
    _ -> MistsOfRlyeh <$> runMessage msg attrs

newtype MistsOfRlyehEffect = MistsOfRlyehEffect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

mistsOfRlyehEffect :: EffectArgs -> MistsOfRlyehEffect
mistsOfRlyehEffect = MistsOfRlyehEffect . uncurry4 (baseAttrs "04029")

instance RunMessage MistsOfRlyehEffect where
  runMessage msg e@(MistsOfRlyehEffect attrs@EffectAttrs {..}) = case msg of
    RevealToken _ iid token -> case effectTarget of
      InvestigatorTarget iid' | iid == iid' -> e <$ when
        (tokenFace token `elem` [Skull, Cultist, Tablet, ElderThing, AutoFail])
        (push $ ChooseAndDiscardCard iid)
      _ -> pure e
    SkillTestEnds _ -> do
      case effectTarget of
        InvestigatorTarget iid -> do
          mSkillTestResult <- fmap skillTestResult <$> getSkillTest
          case mSkillTestResult of
            Just (SucceededBy _ _) -> do
              unblockedConnectedLocationIds <- selectList AccessibleLocation
              let
                moveOptions = chooseOrRunOne
                  iid
                  ([Label "Do not move to a connecting location" []]
                  <> [ targetLabel lid [MoveAction iid lid Free False]
                     | lid <- unblockedConnectedLocationIds
                     ])
              pushAll [moveOptions, DisableEffect effectId]
            _ -> push (DisableEffect effectId)
        _ -> error "Invalid Target"
      pure e
    _ -> MistsOfRlyehEffect <$> runMessage msg attrs

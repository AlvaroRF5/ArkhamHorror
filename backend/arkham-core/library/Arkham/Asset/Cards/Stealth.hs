module Arkham.Asset.Cards.Stealth
  ( stealth
  , Stealth(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.Matcher
import Arkham.SkillType
import Arkham.Target

newtype Stealth = Stealth AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

stealth :: AssetCard Stealth
stealth = asset Stealth Cards.stealth

instance HasAbilities Stealth where
  getAbilities (Stealth attrs) =
    [ restrictedAbility attrs 1 ControlsThis
        $ ActionAbility (Just Action.Evade)
        $ ActionCost 1
    ]

instance RunMessage Stealth where
  runMessage msg a@(Stealth attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      push $ ChooseEvadeEnemy
        iid
        source
        (Just $ toTarget attrs)
        SkillAgility
        AnyEnemy
        False
      pure a
    ChosenEvadeEnemy source eid | isSource attrs source ->
      a <$ push (skillTestModifier source (EnemyTarget eid) (EnemyEvade (-2)))
    AfterSkillTestEnds source target@(EnemyTarget eid) n
      | isSource attrs source && n >= 0 -> do
        let iid = getController attrs
        canDisengage <- iid <=~> InvestigatorCanDisengage
        pushAll
          $ [ CreateWindowModifierEffect
                EffectTurnWindow
                (EffectModifiers $ toModifiers attrs [EnemyCannotEngage iid])
                source
                target
            ]
          <> [ DisengageEnemy iid eid | canDisengage ]
        pure a
    _ -> Stealth <$> runMessage msg attrs

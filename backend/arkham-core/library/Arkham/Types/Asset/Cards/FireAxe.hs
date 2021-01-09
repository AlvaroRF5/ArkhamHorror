module Arkham.Types.Asset.Cards.FireAxe
  ( FireAxe(..)
  , fireAxe
  ) where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner

newtype FireAxe = FireAxe Attrs
  deriving newtype (Show, ToJSON, FromJSON)

fireAxe :: AssetId -> FireAxe
fireAxe uuid = FireAxe $ (baseAttrs uuid "02032") { assetSlots = [HandSlot] }

fightAbility :: Attrs -> Ability
fightAbility attrs = mkAbility
  (toSource attrs)
  1
  (ActionAbility (Just Action.Fight) (ActionCost 1))

reactionAbility :: Attrs -> Ability
reactionAbility attrs = base { abilityLimit = PlayerLimit PerTestOrAbility 3 } -- per attack
  where base = mkAbility (toSource attrs) 2 (ReactionAbility $ ResourceCost 1)

instance HasCount ResourceCount env InvestigatorId => HasModifiersFor env FireAxe where
  getModifiersFor (SkillTestSource _ _ source (Just Action.Fight)) (InvestigatorTarget iid) (FireAxe a)
    | ownedBy a iid && isSource a source
    = do
      resourceCount <- getResourceCount iid
      pure $ toModifiers a [ DamageDealt 1 | resourceCount == 0 ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env FireAxe where
  getActions iid NonFast (FireAxe a) | ownedBy a iid = do
    fightAvailable <- hasFightActions iid NonFast
    pure [ ActivateCardAbilityAction iid (fightAbility a) | fightAvailable ]
  getActions iid (WhenSkillTest _) (FireAxe a) | ownedBy a iid = do
    msource <- asks $ getSource ForSkillTest
    let
      using = case msource of
        Just (SkillTestSource _ _ source (Just Action.Fight))
          | isSource a source -> True
        _ -> False
    pure [ ActivateCardAbilityAction iid (reactionAbility a) | using ]
  getActions _ _ _ = pure []

instance (AssetRunner env) => RunMessage env FireAxe where
  runMessage msg a@(FireAxe attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ unshiftMessages
        [ CreateSkillTestEffect
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillCombat 1])
          source
          (InvestigatorTarget iid)
        , ChooseFightEnemy iid source SkillCombat False
        ]
    UseCardAbility iid source _ 2 _ | isSource attrs source ->
      a <$ unshiftMessage
        (CreateSkillTestEffect
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillCombat 2])
          source
          (InvestigatorTarget iid)
        )
    _ -> FireAxe <$> runMessage msg attrs

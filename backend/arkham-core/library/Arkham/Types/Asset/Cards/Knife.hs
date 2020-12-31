{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Asset.Cards.Knife
  ( Knife(..)
  , knife
  )
where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner

newtype Knife = Knife Attrs
  deriving newtype (Show, ToJSON, FromJSON)

knife :: AssetId -> Knife
knife uuid = Knife $ (baseAttrs uuid "01086") { assetSlots = [HandSlot] }

instance HasModifiersFor env Knife where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Knife where
  getActions iid NonFast (Knife a) | ownedBy a iid = do
    fightAvailable <- hasFightActions iid NonFast
    pure
      $ [ ActivateCardAbilityAction
            iid
            (mkAbility
              (toSource a)
              1
              (ActionAbility (Just Action.Fight) (ActionCost 1))
            )
        | fightAvailable
        ]
      <> [ ActivateCardAbilityAction
             iid
             (mkAbility
               (toSource a)
               2
               (ActionAbility (Just Action.Fight) (ActionCost 1))
             )
         | fightAvailable
         ]
  getActions _ _ _ = pure []

instance (AssetRunner env) => RunMessage env Knife where
  runMessage msg a@(Knife attrs) = case msg of
    UseCardAbility iid source _ 1 | isSource attrs source ->
      a <$ unshiftMessages
        [ CreateSkillTestEffect
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillCombat 1])
          source
          (InvestigatorTarget iid)
        , ChooseFightEnemy iid source SkillCombat False
        ]
    UseCardAbility iid source _ 2 | isSource attrs source ->
      a <$ unshiftMessages
        [ Discard (toTarget attrs)
        , CreateSkillTestEffect
          (EffectModifiers
          $ toModifiers attrs [SkillModifier SkillCombat 2, DamageDealt 1]
          )
          source
          (InvestigatorTarget iid)
        , ChooseFightEnemy iid source SkillCombat False
        ]
    _ -> Knife <$> runMessage msg attrs

module Arkham.Types.Asset.Cards.FortyFiveAutomatic
  ( FortyFiveAutomatic(..)
  , fortyFiveAutomatic
  )
where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Asset.Uses

newtype FortyFiveAutomatic = FortyFiveAutomatic Attrs
  deriving newtype (Show, ToJSON, FromJSON)

fortyFiveAutomatic :: AssetId -> FortyFiveAutomatic
fortyFiveAutomatic uuid =
  FortyFiveAutomatic $ (baseAttrs uuid "01016") { assetSlots = [HandSlot] }

instance HasModifiersFor env FortyFiveAutomatic where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env FortyFiveAutomatic where
  getActions iid window (FortyFiveAutomatic a) | ownedBy a iid = do
    fightAvailable <- hasFightActions iid window
    pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility
            (toSource a)
            1
            (ActionAbility
              (Just Action.Fight)
              (Costs [ActionCost 1, UseCost (toId a) Ammo 1])
            )
          )
      | fightAvailable
      ]
  getActions _ _ _ = pure []

instance AssetRunner env => RunMessage env FortyFiveAutomatic where
  runMessage msg a@(FortyFiveAutomatic attrs) = case msg of
    InvestigatorPlayAsset _ aid _ _ | aid == assetId attrs ->
      FortyFiveAutomatic <$> runMessage msg (attrs & usesL .~ Uses Ammo 4)
    UseCardAbility iid source _ 1 | isSource attrs source ->
      a <$ unshiftMessages
        [ CreateSkillTestEffect
          (EffectModifiers
          $ toModifiers attrs [DamageDealt 1, SkillModifier SkillCombat 1]
          )
          source
          (InvestigatorTarget iid)
        , ChooseFightEnemy iid source SkillCombat False
        ]
    _ -> FortyFiveAutomatic <$> runMessage msg attrs

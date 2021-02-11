module Arkham.Types.Asset.Cards.Blackjack
  ( blackjack
  , Blackjack(..)
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.AssetId
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Effect.Window
import Arkham.Types.EffectMetadata
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Slot
import Arkham.Types.Target

newtype Blackjack = Blackjack AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

blackjack :: AssetId -> Blackjack
blackjack uuid =
  Blackjack $ (baseAttrs uuid "02016") { assetSlots = [HandSlot] }

instance ActionRunner env => HasActions env Blackjack where
  getActions iid window (Blackjack a) | ownedBy a iid = do
    fightAvailable <- hasFightActions iid window
    pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility
            (toSource a)
            1
            (ActionAbility (Just Action.Fight) (ActionCost 1))
          )
      | fightAvailable
      ]
  getActions _ _ _ = pure []

instance HasModifiersFor env Blackjack where
  getModifiersFor = noModifiersFor

instance (HasQueue env, HasModifiersFor env ()) => RunMessage env Blackjack where
  runMessage msg a@(Blackjack attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ unshiftMessages
        [ CreateWindowModifierEffect
          EffectSkillTestWindow
          (EffectModifiers $ toModifiers
            attrs
            [SkillModifier SkillCombat 1, DoesNotDamageOtherInvestigator]
          )
          source
          (InvestigatorTarget iid)
        , ChooseFightEnemy iid source SkillCombat mempty False
        ]
    _ -> Blackjack <$> runMessage msg attrs

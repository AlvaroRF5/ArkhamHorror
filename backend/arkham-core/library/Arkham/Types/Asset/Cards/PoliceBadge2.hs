module Arkham.Types.Asset.Cards.PoliceBadge2
  ( PoliceBadge2(..)
  , policeBadge2
  )
where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner

newtype PoliceBadge2 = PoliceBadge2 Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

policeBadge2 :: AssetId -> PoliceBadge2
policeBadge2 uuid =
  PoliceBadge2 $ (baseAttrs uuid "01027") { assetSlots = [AccessorySlot] }

instance HasModifiersFor env PoliceBadge2 where
  getModifiersFor _ (InvestigatorTarget iid) (PoliceBadge2 a) =
    pure [ toModifier a (SkillModifier SkillWillpower 1) | ownedBy a iid ]
  getModifiersFor _ _ _ = pure []

instance HasActions env PoliceBadge2 where
  getActions iid (DuringTurn InvestigatorAtYourLocation) (PoliceBadge2 a)
    | ownedBy a iid = pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility (toSource a) 1 (ActionAbility Nothing $ ActionCost 1))
      ]
  getActions _ _ _ = pure []

instance AssetRunner env => RunMessage env PoliceBadge2 where
  runMessage msg a@(PoliceBadge2 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      activeInvestigatorId <- unActiveInvestigatorId <$> getId ()
      a <$ unshiftMessages
        [Discard (toTarget attrs), GainActions activeInvestigatorId source 2]
    _ -> PoliceBadge2 <$> runMessage msg attrs

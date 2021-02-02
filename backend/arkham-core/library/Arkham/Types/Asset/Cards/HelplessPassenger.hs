module Arkham.Types.Asset.Cards.HelplessPassenger
  ( helplessPassenger
  , HelplessPassenger(..)
  ) where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Asset.Attrs

newtype HelplessPassenger = HelplessPassenger Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

helplessPassenger :: AssetId -> HelplessPassenger
helplessPassenger uuid = HelplessPassenger $ (baseAttrs uuid "02179")
  { assetHealth = Just 1
  , assetSanity = Just 1
  , assetIsStory = True
  }

ability :: Attrs -> Ability
ability attrs =
  mkAbility (toSource attrs) 1 (ActionAbility (Just Parley) $ ActionCost 1)

instance HasId LocationId env InvestigatorId => HasActions env HelplessPassenger where
  getActions iid NonFast (HelplessPassenger attrs) = do
    lid <- getId iid
    case assetLocation attrs of
      Just location -> pure
        [ ActivateCardAbilityAction iid (ability attrs)
        | lid == location && isNothing (assetInvestigator attrs)
        ]
      _ -> pure mempty
  getActions iid window (HelplessPassenger attrs) = getActions iid window attrs

instance HasModifiersFor env HelplessPassenger where
  getModifiersFor = noModifiersFor

instance
  ( HasQueue env
  , HasModifiersFor env ()
  , HasId LocationId env InvestigatorId
  , HasSet InScenarioInvestigatorId env ()
  , HasId (Maybe LocationId) env (Direction, LocationId)
  )
  => RunMessage env HelplessPassenger where
  runMessage msg a@(HelplessPassenger attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      lid <- getId @LocationId iid
      spawnAt <- fromMaybe lid <$> getId (LeftOf, lid)
      a <$ unshiftMessage (AttachAsset assetId (LocationTarget spawnAt))
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ unshiftMessage (TakeControlOfAsset iid assetId)
    When (Discard target) | isTarget attrs target -> do
      investigatorIds <- map unInScenarioInvestigatorId <$> getSetList ()
      a <$ unshiftMessages
        [ InvestigatorAssignDamage iid' (toSource attrs) DamageAny 0 1
        | iid' <- investigatorIds
        ]
    _ -> HelplessPassenger <$> runMessage msg attrs

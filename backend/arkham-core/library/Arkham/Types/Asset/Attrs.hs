{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Asset.Attrs where

import Arkham.Import

import Arkham.Types.Asset.Uses
import Arkham.Types.Trait

data Attrs = Attrs
  { assetName :: Text
  , assetId :: AssetId
  , assetCardCode :: CardCode
  , assetCost :: CardCost
  , assetInvestigator :: Maybe InvestigatorId
  , assetLocation :: Maybe LocationId
  , assetEnemy :: Maybe EnemyId
  , assetActions :: [Message]
  , assetSlots :: [SlotType]
  , assetHealth :: Maybe Int
  , assetSanity :: Maybe Int
  , assetHealthDamage :: Int
  , assetSanityDamage :: Int
  , assetTraits :: HashSet Trait
  , assetUses :: Uses
  , assetExhausted :: Bool
  , assetDoom :: Int
  , assetHorror :: Maybe Int
  , assetCanLeavePlayByNormalMeans :: Bool
  }
  deriving stock (Show, Generic)

instance ToJSON Attrs where
  toJSON = genericToJSON $ aesonOptions $ Just "asset"
  toEncoding = genericToEncoding $ aesonOptions $ Just "asset"

instance FromJSON Attrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "asset"

baseAttrs :: AssetId -> CardCode -> Attrs
baseAttrs aid cardCode =
  let
    MkPlayerCard {..} =
      fromJustNote "missing player card" (lookup cardCode allPlayerCards)
        $ CardId (unAssetId aid)
  in
    Attrs
      { assetName = pcName
      , assetId = aid
      , assetCardCode = cardCode
      , assetCost = pcCost
      , assetInvestigator = Nothing
      , assetLocation = Nothing
      , assetEnemy = Nothing
      , assetActions = mempty
      , assetSlots = mempty
      , assetHealth = Nothing
      , assetSanity = Nothing
      , assetHealthDamage = 0
      , assetSanityDamage = 0
      , assetTraits = pcTraits
      , assetUses = NoUses
      , assetExhausted = False
      , assetDoom = 0
      , assetHorror = Nothing
      , assetCanLeavePlayByNormalMeans = True
      }

instance Entity Attrs where
  toSource = AssetSource . assetId
  toTarget = AssetTarget . assetId
  isSource Attrs { assetId } (AssetSource aid) = assetId == aid
  isSource _ _ = False
  isTarget Attrs { assetId } (AssetTarget aid) = assetId == aid
  isTarget _ _ = False

instance HasId AssetId env Attrs where
  getId = pure . assetId

ownedBy :: Attrs -> InvestigatorId -> Bool
ownedBy Attrs {..} = (== assetInvestigator) . Just

doom :: Lens' Attrs Int
doom = lens assetDoom $ \m x -> m { assetDoom = x }

exhausted :: Lens' Attrs Bool
exhausted = lens assetExhausted $ \m x -> m { assetExhausted = x }

uses :: Lens' Attrs Uses
uses = lens assetUses $ \m x -> m { assetUses = x }

investigator :: Lens' Attrs (Maybe InvestigatorId)
investigator = lens assetInvestigator $ \m x -> m { assetInvestigator = x }

location :: Lens' Attrs (Maybe LocationId)
location = lens assetLocation $ \m x -> m { assetLocation = x }

enemy :: Lens' Attrs (Maybe EnemyId)
enemy = lens assetEnemy $ \m x -> m { assetEnemy = x }

getInvestigator :: HasCallStack => Attrs -> InvestigatorId
getInvestigator = fromJustNote "asset must be owned" . view investigator

healthDamage :: Lens' Attrs Int
healthDamage = lens assetHealthDamage $ \m x -> m { assetHealthDamage = x }

sanityDamage :: Lens' Attrs Int
sanityDamage = lens assetSanityDamage $ \m x -> m { assetSanityDamage = x }

defeated :: Attrs -> Bool
defeated Attrs {..} =
  maybe False (assetHealthDamage >=) assetHealth
    || maybe False (assetSanityDamage >=) assetSanity

instance HasActions env Attrs where
  getActions _ _ _ = pure []

is :: Target -> Attrs -> Bool
is (AssetTarget aid) a = aid == assetId a
is (CardCodeTarget cardCode) a = cardCode == assetCardCode a
is (CardIdTarget cardId) a = unCardId cardId == unAssetId (assetId a)
is _ _ = False

instance (HasQueue env, HasModifiersFor env ()) => RunMessage env Attrs where
  runMessage msg a@Attrs {..} = case msg of
    ReadyExhausted -> case assetInvestigator of
      Just iid -> do
        modifiers <- getModifiersFor (toSource a) (InvestigatorTarget iid) ()
        if ControlledAssetsCannotReady `elem` modifiers
          then pure a
          else pure $ a & exhausted .~ False
      Nothing -> pure $ a & exhausted .~ False
    CheckDefeated ->
      a <$ when (defeated a) (unshiftMessage (AssetDefeated assetId))
    AssetDamage aid _ health sanity | aid == assetId ->
      pure $ a & healthDamage +~ health & sanityDamage +~ sanity
    InvestigatorEliminated iid | assetInvestigator == Just iid ->
      a <$ unshiftMessage (Discard (AssetTarget assetId))
    AddUses target useType' n | target `is` a -> case assetUses of
      Uses useType'' m | useType' == useType'' ->
        pure $ a & uses .~ Uses useType' (n + m)
      _ -> error "Trying to add the wrong use type"
    AttachAsset aid target | aid == assetId -> case target of
      LocationTarget lid -> pure $ a & location ?~ lid
      EnemyTarget eid -> pure $ a & enemy ?~ eid
      _ -> error "Cannot attach asset to that type"
    RemoveFromGame target | target `is` a ->
      a <$ unshiftMessage (RemovedFromPlay (AssetSource assetId))
    Discard target | target `is` a ->
      a <$ unshiftMessage (RemovedFromPlay $ toSource a)
    InvestigatorPlayAsset iid aid _ _ | aid == assetId ->
      pure $ a & investigator ?~ iid
    TakeControlOfAsset iid aid | aid == assetId ->
      pure $ a & investigator ?~ iid
    Exhaust target | target `is` a -> pure $ a & exhausted .~ True
    Ready target | target `is` a -> case assetInvestigator of
      Just iid -> do
        modifiers <- getModifiersFor (toSource a) (InvestigatorTarget iid) ()
        if ControlledAssetsCannotReady `elem` modifiers
          then pure a
          else pure $ a & exhausted .~ False
      Nothing -> pure $ a & exhausted .~ False
    _ -> pure a

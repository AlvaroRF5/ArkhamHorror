module Arkham.ModifierData (
  module Arkham.ModifierData,
) where

import Arkham.Prelude

import Arkham.Id
import Arkham.Json
import Arkham.Modifier

newtype ModifierData = ModifierData {mdModifiers :: [Modifier]}
  deriving stock (Show, Eq, Generic)

instance ToJSON ModifierData where
  toJSON = genericToJSON $ aesonOptions $ Just "md"
  toEncoding = genericToEncoding $ aesonOptions $ Just "md"

data LocationMetadata = LocationMetadata
  { lmConnectedLocations :: [LocationId]
  , lmInvestigators :: [InvestigatorId]
  , lmEnemies :: [EnemyId]
  , lmTreacheries :: [TreacheryId]
  , lmAssets :: [AssetId]
  , lmEvents :: [EventId]
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON LocationMetadata where
  toJSON = genericToJSON $ aesonOptions $ Just "lm"
  toEncoding = genericToEncoding $ aesonOptions $ Just "lm"

newtype ConnectionData = ConnectionData {cdConnectedLocations :: [LocationId]}
  deriving stock (Show, Eq, Generic)

instance ToJSON ConnectionData where
  toJSON = genericToJSON $ aesonOptions $ Just "cd"
  toEncoding = genericToEncoding $ aesonOptions $ Just "cd"

data EnemyMetadata = EnemyMetadata
  { emEngagedInvestigators :: [InvestigatorId]
  , emTreacheries :: [TreacheryId]
  , emAssets :: [AssetId]
  , emModifiers :: [Modifier]
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON EnemyMetadata where
  toJSON = genericToJSON $ aesonOptions $ Just "em"
  toEncoding = genericToEncoding $ aesonOptions $ Just "em"

data AssetMetadata = AssetMetadata
  { amEvents :: [EventId]
  , amAssets :: [AssetId]
  , amTreacheries :: [TreacheryId]
  , amModifiers :: [Modifier]
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON AssetMetadata where
  toJSON = genericToJSON $ aesonOptions $ Just "am"
  toEncoding = genericToEncoding $ aesonOptions $ Just "am"

module Arkham.CampaignLog where

import Arkham.Prelude

import Arkham.Campaign.Option
import Arkham.CampaignLogKey
import Arkham.Json

data CampaignLog = CampaignLog
  { campaignLogRecorded :: Set CampaignLogKey
  , campaignLogCrossedOut :: Set CampaignLogKey
  , campaignLogRecordedCounts :: Map CampaignLogKey Int
  , campaignLogRecordedSets :: Map CampaignLogKey [SomeRecorded]
  , campaignLogOrderedKeys :: [CampaignLogKey]
  , campaignLogOptions :: Set CampaignOption
  }
  deriving stock (Show, Generic, Eq)

emptyCampaignLog :: CampaignLog -> Bool
emptyCampaignLog CampaignLog {..} =
  null campaignLogRecorded
    && null campaignLogCrossedOut
    && null campaignLogRecordedCounts
    && null campaignLogRecordedSets
    && null campaignLogOrderedKeys
    && null campaignLogOptions

recordedL :: Lens' CampaignLog (Set CampaignLogKey)
recordedL = lens campaignLogRecorded $ \m x -> m {campaignLogRecorded = x}

optionsL :: Lens' CampaignLog (Set CampaignOption)
optionsL = lens campaignLogOptions $ \m x -> m {campaignLogOptions = x}

crossedOutL :: Lens' CampaignLog (Set CampaignLogKey)
crossedOutL =
  lens campaignLogCrossedOut $ \m x -> m {campaignLogCrossedOut = x}

recordedSetsL :: Lens' CampaignLog (Map CampaignLogKey [SomeRecorded])
recordedSetsL =
  lens campaignLogRecordedSets $ \m x -> m {campaignLogRecordedSets = x}

recordedCountsL :: Lens' CampaignLog (Map CampaignLogKey Int)
recordedCountsL =
  lens campaignLogRecordedCounts $ \m x -> m {campaignLogRecordedCounts = x}

orderedKeysL :: Lens' CampaignLog [CampaignLogKey]
orderedKeysL =
  lens campaignLogOrderedKeys $ \m x -> m {campaignLogOrderedKeys = x}

instance ToJSON CampaignLog where
  toJSON = genericToJSON $ aesonOptions $ Just "campaignLog"
  toEncoding = genericToEncoding $ aesonOptions $ Just "campaignLog"

instance FromJSON CampaignLog where
  parseJSON = genericParseJSON $ aesonOptions $ Just "campaignLog"

mkCampaignLog :: CampaignLog
mkCampaignLog =
  CampaignLog
    { campaignLogRecorded = mempty
    , campaignLogCrossedOut = mempty
    , campaignLogRecordedCounts = mempty
    , campaignLogRecordedSets = mempty
    , campaignLogOrderedKeys = mempty
    , campaignLogOptions = mempty
    }

setCampaignLogKey :: CampaignLogKey -> CampaignLog -> CampaignLog
setCampaignLogKey key = recordedL %~ insertSet key

deleteCampaignLogKey :: CampaignLogKey -> CampaignLog -> CampaignLog
deleteCampaignLogKey key = recordedL %~ deleteSet key

setCampaignLogRecorded :: CampaignLogKey -> [SomeRecorded] -> CampaignLog -> CampaignLog
setCampaignLogRecorded key entries = recordedSetsL %~ insertMap key entries

setCampaignLogRecordedCount :: CampaignLogKey -> Int -> CampaignLog -> CampaignLog
setCampaignLogRecordedCount key n = recordedCountsL %~ insertMap key n

setCampaignLogOption :: CampaignOption -> CampaignLog -> CampaignLog
setCampaignLogOption key = optionsL %~ insertSet key

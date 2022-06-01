module Api.Arkham.Export where

import Import.NoFoundation

import Arkham.Game
import Api.Arkham.Types.MultiplayerVariant
import Json

data ArkhamExport = ArkhamExport
  { aeCampaignPlayers :: [Text]
  , aeCampaignData :: ArkhamGameExportData
  }
  deriving stock Generic

instance ToJSON ArkhamExport where
  toJSON = genericToJSON (aesonOptions $ Just "ae")

instance FromJSON ArkhamExport where
  parseJSON = genericParseJSON (aesonOptions $ Just "ae")

data ArkhamGameExportData = ArkhamGameExportData
  { agedName :: Text
  , agedCurrentData :: Game
  , agedChoices :: [Choice]
  , agedLog :: [Text]
  , agedMultiplayerVariant :: MultiplayerVariant
  }
  deriving stock Generic

instance ToJSON ArkhamGameExportData where
  toJSON = genericToJSON (aesonOptions $ Just "aged")

instance FromJSON ArkhamGameExportData where
  parseJSON = genericParseJSON (aesonOptions $ Just "aged")

arkhamGameToExportData :: ArkhamGame -> ArkhamGameExportData
arkhamGameToExportData ArkhamGame {..} = ArkhamGameExportData
  { agedName = arkhamGameName
  , agedCurrentData = arkhamGameCurrentData
  , agedChoices = arkhamGameChoices
  , agedLog = arkhamGameLog
  , agedMultiplayerVariant = arkhamGameMultiplayerVariant
  }

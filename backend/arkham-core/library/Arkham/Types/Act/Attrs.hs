module Arkham.Types.Act.Attrs where

import Arkham.Json
import Arkham.Types.ActId
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.Window
import ClassyPrelude
import Lens.Micro

data Attrs = Attrs
  { actCanAdvance :: Bool
  , actId         :: ActId
  , actName       :: Text
  , actSequence   :: Text
  , actFlipped :: Bool
  , actClues :: Maybe Int
  }
  deriving stock (Show, Generic)

instance ToJSON Attrs where
  toJSON = genericToJSON $ aesonOptions $ Just "act"
  toEncoding = genericToEncoding $ aesonOptions $ Just "act"

instance FromJSON Attrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "act"

canAdvance :: Lens' Attrs Bool
canAdvance = lens actCanAdvance $ \m x -> m { actCanAdvance = x }

sequence :: Lens' Attrs Text
sequence = lens actSequence $ \m x -> m { actSequence = x }

flipped :: Lens' Attrs Bool
flipped = lens actFlipped $ \m x -> m { actFlipped = x }

baseAttrs :: ActId -> Text -> Text -> Attrs
baseAttrs aid name seq' = Attrs
  { actCanAdvance = False
  , actId = aid
  , actName = name
  , actSequence = seq'
  , actFlipped = False
  , actClues = Nothing
  }

instance HasActions env investigator Attrs where
  getActions _ FastPlayerWindow Attrs {..} =
    pure [ AdvanceAct actId | actCanAdvance ]
  getActions _ _ _ = pure []

instance (HasQueue env) => RunMessage env Attrs where
  runMessage _msg a@Attrs {..} = pure a

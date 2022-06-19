module Arkham.Campaigns.ThePathToCarcosa.Helpers where

import Arkham.Prelude

import Arkham.Game.Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.CampaignLogKey
import Arkham.Message

getConviction :: (Monad m, HasGame m) => m Int
getConviction = getRecordCount Conviction

getDoubt :: (Monad m, HasGame m) => m Int
getDoubt = getRecordCount Doubt

getMoreConvictionThanDoubt :: (Monad m, HasGame m) => m Bool
getMoreConvictionThanDoubt = liftA2 (>) getConviction getDoubt

markConviction :: (Monad m, HasGame m) => m Message
markConviction = do
  n <- getConviction
  pure $ RecordCount Conviction (n + 1)

markDoubt :: (Monad m, HasGame m) => m Message
markDoubt = do
  n <- getDoubt
  pure $ RecordCount Doubt (n + 1)

module Arkham.Scenarios.TheEssexCountyExpress.Helpers where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Direction
import Arkham.Matcher
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id

leftmostLocation :: (Monad m, HasGame m) => LocationId -> m LocationId
leftmostLocation lid = do
  mlid' <- selectOne $ LocationInDirection LeftOf $ LocationWithId lid
  maybe (pure lid) leftmostLocation mlid'

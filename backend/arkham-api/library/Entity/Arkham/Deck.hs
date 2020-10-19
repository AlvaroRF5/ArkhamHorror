{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE UndecidableInstances #-}
module Entity.Arkham.Deck
  ( module Entity.Arkham.Deck
  )
where

import ClassyPrelude
import Data.UUID
import Database.Persist.Postgresql.JSON ()
import Database.Persist.TH
import Entity.Arkham.ArkhamDBDecklist
import Entity.User
import Json
import Orphans ()

share [mkPersist sqlSettings, mkDeleteCascade sqlSettings] [persistLowerCase|
ArkhamDeck sql=arkham_decks
  Id UUID default=uuid_generate_v4()
  userId UserId
  name Text
  investigatorName Text
  list ArkhamDBDecklist
  deriving Generic Show
|]

instance ToJSON ArkhamDeck where
  toJSON = genericToJSON $ aesonOptions $ Just "arkhamDeck"
  toEncoding = genericToEncoding $ aesonOptions $ Just "arkhamDeck"

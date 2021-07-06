module Api.Handler.Arkham.Decks
  ( getApiV1ArkhamDecksR
  , postApiV1ArkhamDecksR
  , deleteApiV1ArkhamDeckR
  , putApiV1ArkhamGameDecksR
  )
where

import Import hiding (delete, on, (==.))

import Api.Arkham.Helpers
import Arkham.Game
import Arkham.Types.Game
import Arkham.Types.Message
import Control.Monad.Random (mkStdGen)
import Database.Esqueleto.Experimental
import Json
import Network.HTTP.Conduit (simpleHttp)
import Safe (fromJustNote)

getApiV1ArkhamDecksR :: Handler [Entity ArkhamDeck]
getApiV1ArkhamDecksR = do
  userId <- fromJustNote "Not authenticated" <$> getRequestUserId
  runDB $ select $ do
    decks <- from $ table @ArkhamDeck
    where_ (decks ^. ArkhamDeckUserId ==. val userId)
    pure decks

data CreateDeckPost = CreateDeckPost
  { deckId :: Text
  , deckName :: Text
  , deckUrl :: Text
  }
  deriving stock (Show, Generic)
  deriving anyclass FromJSON

newtype UpgradeDeckPost = UpgradeDeckPost
  { udpDeckUrl :: Maybe Text
  }
  deriving stock (Show, Generic)

instance FromJSON UpgradeDeckPost where
  parseJSON = genericParseJSON $ aesonOptions $ Just "udp"

postApiV1ArkhamDecksR :: Handler (Entity ArkhamDeck)
postApiV1ArkhamDecksR = do
  userId <- fromJustNote "Not authenticated" <$> getRequestUserId
  postData <- requireCheckJsonBody
  edeck <- fromPostData userId postData
  case edeck of
    Left err -> error err
    Right deck -> do
      deckId <- runDB (insert deck)
      pure $ Entity deckId deck

putApiV1ArkhamGameDecksR :: ArkhamGameId -> Handler ()
putApiV1ArkhamGameDecksR gameId = do
  userId <- fromJustNote "Not authenticated" <$> getRequestUserId
  ArkhamGame {..} <- runDB $ get404 gameId
  postData <- requireCheckJsonBody
  let
    Game {..} = arkhamGameCurrentData
    investigatorId = fromJustNote "Missing"
      $ lookup (fromIntegral $ fromSqlKey userId) gamePlayers
  msg <- case udpDeckUrl postData of
    Nothing -> pure Done
    Just deckUrl -> do
      edecklist <- getDeckList deckUrl
      case edecklist of
        Left err -> error $ show err
        Right decklist -> do
          cards <- liftIO $ loadDecklistCards decklist
          pure $ UpgradeDeck investigatorId cards

  gameRef <- newIORef arkhamGameCurrentData
  queueRef <- newIORef (msg : arkhamGameQueue)
  genRef <- newIORef (mkStdGen gameSeed)
  runGameApp (GameApp gameRef queueRef genRef $ pure . const ()) runMessages
  ge <- readIORef gameRef
  updatedQueue <- readIORef queueRef
  let updatedMessages = []
  writeChannel <- getChannel gameId
  liftIO $ atomically $ writeTChan
    writeChannel
    (encode
      (Entity gameId (ArkhamGame arkhamGameName ge updatedQueue updatedMessages)
      )
    )
  void $ runDB
    (replace gameId (ArkhamGame arkhamGameName ge updatedQueue updatedMessages))

fromPostData
  :: (MonadIO m) => UserId -> CreateDeckPost -> m (Either String ArkhamDeck)
fromPostData userId CreateDeckPost {..} = do
  edecklist <- getDeckList deckUrl
  pure $ case edecklist of
    Left err -> Left err
    Right decklist -> Right $ ArkhamDeck
      { arkhamDeckUserId = userId
      , arkhamDeckInvestigatorName = tshow $ investigator_name decklist
      , arkhamDeckName = deckName
      , arkhamDeckList = decklist
      }

getDeckList :: MonadIO m => Text -> m (Either String ArkhamDBDecklist)
getDeckList url = liftIO $ eitherDecode <$> simpleHttp (unpack url)

deleteApiV1ArkhamDeckR :: ArkhamDeckId -> Handler ()
deleteApiV1ArkhamDeckR deckId = do
  userId <- fromJustNote "Not authenticated" <$> getRequestUserId
  void $ runDB $ do
    delete $ do
      decks <- from $ table @ArkhamDeck
      where_ $ decks ^. persistIdField ==. val deckId
      where_ $ decks ^. ArkhamDeckUserId ==. val userId

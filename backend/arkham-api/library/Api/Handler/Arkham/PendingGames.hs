module Api.Handler.Arkham.PendingGames
  ( putApiV1ArkhamPendingGameR
  ) where

import Import hiding (on, (==.))

import Api.Arkham.Helpers
import Arkham.Game
import Arkham.Types.Card.CardCode
import Arkham.Types.Game
import Arkham.Types.Id
import Arkham.Types.Investigator
import Control.Monad.Random (mkStdGen)
import Data.Aeson
import Data.Coerce
import Safe (fromJustNote)

newtype JoinGameJson = JoinGameJson { deckId :: ArkhamDeckId }
  deriving stock (Show, Generic)
  deriving anyclass (FromJSON)

putApiV1ArkhamPendingGameR :: ArkhamGameId -> Handler (PublicGame ArkhamGameId)
putApiV1ArkhamPendingGameR gameId = do
  userId <- fromJustNote "Not authenticated" <$> getRequestUserId
  JoinGameJson {..} <- requireCheckJsonBody
  ArkhamGame {..} <- runDB $ get404 gameId

  deck <- runDB $ get404 deckId
  when (arkhamDeckUserId deck /= userId) notFound
  (iid, decklist) <- liftIO $ loadDecklist deck
  when (iid `member` gameInvestigators arkhamGameCurrentData)
    $ invalidArgs ["Investigator already taken"]

  runDB $ insert_ $ ArkhamPlayer userId gameId (coerce iid)

  let currentQueue = maybe [] choiceMessages $ headMay arkhamGameChoices

  gameRef <- newIORef arkhamGameCurrentData
  queueRef <- newIORef currentQueue
  genRef <- newIORef (mkStdGen (gameSeed arkhamGameCurrentData))
  runGameApp (GameApp gameRef queueRef genRef (pure . const ())) $ do
    addInvestigator (lookupInvestigator iid) decklist
    runMessages False

  updatedGame <- readIORef gameRef
  updatedQueue <- readIORef queueRef
  let updatedMessages = []

  let diffedGame = diff arkhamGameCurrentData updatedGame

  writeChannel <- getChannel gameId
  liftIO
    $ atomically
    $ writeTChan writeChannel
    $ encode
    $ GameUpdate
    $ PublicGame gameId arkhamGameName updatedMessages updatedGame

  runDB $ replace gameId $ ArkhamGame
    arkhamGameName
    updatedGame
    (Choice diffedGame updatedQueue : arkhamGameChoices)
    updatedMessages
    arkhamGameMultiplayerVariant

  pure $ toPublicGame $ Entity gameId $ ArkhamGame
    arkhamGameName
    updatedGame
    (Choice diffedGame updatedQueue : arkhamGameChoices)
    updatedMessages
    arkhamGameMultiplayerVariant

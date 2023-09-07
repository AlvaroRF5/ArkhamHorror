module Arkham.Helpers.Window where

import Arkham.Prelude

import Arkham.Classes.HasQueue
import Arkham.Classes.Query
import {-# SOURCE #-} Arkham.Game ()
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing
import Arkham.Window
import Arkham.Window qualified as Window

checkWindows :: HasGame m => [Window] -> m Message
checkWindows windows' = do
  iids <- selectList UneliminatedInvestigator
  if null iids
    then do
      iids' <- selectList Anyone
      pure $ CheckWindow iids' windows'
    else pure $ CheckWindow iids windows'

windows :: HasGame m => [WindowType] -> m [Message]
windows windows' = do
  iids <- selectList UneliminatedInvestigator
  pure $ do
    timing <- [Timing.When, Timing.AtIf, Timing.After]
    [CheckWindow iids $ map (mkWindow timing) windows']

wouldWindows :: (MonadRandom m, HasGame m) => WindowType -> m (BatchId, [Message])
wouldWindows window = do
  batchId <- getRandom
  iids <- selectList UneliminatedInvestigator
  pure
    ( batchId
    , [ CheckWindow iids [Window timing window (Just batchId)]
      | timing <- [Timing.When, Timing.AtIf, Timing.After]
      ]
    )

frame :: HasGame m => WindowType -> m (Message, Message, Message)
frame window = do
  iids <- selectList UneliminatedInvestigator
  pure
    ( CheckWindow iids [mkWindow Timing.When window]
    , CheckWindow iids [mkWindow Timing.AtIf window]
    , CheckWindow iids [mkWindow Timing.After window]
    )

doFrame :: HasGame m => Message -> WindowType -> m [Message]
doFrame msg window = do
  (before, atIf, after) <- frame window
  pure [before, atIf, Do msg, after]

wouldDo
  :: (MonadRandom m, HasGame m, HasQueue Message m) => Message -> WindowType -> WindowType -> m ()
wouldDo msg wouldWindow window = do
  (batchId, wouldWindowsMsgs) <- wouldWindows wouldWindow
  framed <- doFrame msg window
  push $ Would batchId $ wouldWindowsMsgs <> framed

{- | Take a message which would operate on some value n and instead expand the
windows to add a single one at a time
-}
wouldDoEach
  :: (MonadRandom m, HasGame m, HasQueue Message m)
  => Int
  -> Message
  -> WindowType -- outer would window
  -> WindowType -- would window
  -> WindowType -- outer window
  -> WindowType -- window
  -> m ()
wouldDoEach n msg outerWouldWindow wouldWindow outerWindow window = do
  (outerBatchId, outerWouldWindowsMsgs) <- wouldWindows outerWouldWindow
  (outerBefore, outerAtIf, outerAfter) <- frame outerWindow
  frames <- for [1 .. n] $ \_ -> do
    (innerBatchId, innerWouldWindowsMsgs) <- wouldWindows wouldWindow
    framed <- doFrame msg window
    pure $ Would innerBatchId $ innerWouldWindowsMsgs <> framed

  push
    $ Would outerBatchId
    $ outerWouldWindowsMsgs <> [outerBefore, outerAtIf] <> frames <> [outerAfter]

splitWithWindows :: HasGame m => Message -> [WindowType] -> m [Message]
splitWithWindows msg windows' = do
  iids <- selectList UneliminatedInvestigator
  pure
    $ [CheckWindow iids $ map (mkWindow Timing.When) windows']
      <> [msg]
      <> [CheckWindow iids $ map (mkWindow Timing.After) windows']

defeatedEnemy :: [Window] -> EnemyId
defeatedEnemy =
  fromMaybe (error "missing enemy") . asum . map \case
    (windowType -> Window.EnemyDefeated _ _ eid) -> Just eid
    _ -> Nothing

evadedEnemy :: [Window] -> EnemyId
evadedEnemy =
  fromMaybe (error "missing enemy") . asum . map \case
    (windowType -> Window.EnemyEvaded _ eid) -> Just eid
    _ -> Nothing

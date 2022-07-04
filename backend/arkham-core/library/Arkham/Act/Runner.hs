{-# OPTIONS_GHC -Wno-orphans #-}
module Arkham.Act.Runner
  ( module Arkham.Act.Runner
  , module X
  ) where

import Arkham.Prelude

import Arkham.Act.Attrs as X
import Arkham.Act.Sequence as X
import Arkham.Classes
import Arkham.Cost as X
import Arkham.Game.Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Matcher hiding ( FastPlayerWindow )
import Arkham.Message
import Arkham.Source
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Window

advanceActSideA
  :: (Monad m, HasGame m) => ActAttrs -> AdvancementMethod -> m [Message]
advanceActSideA attrs advanceMode = do
  leadInvestigatorId <- getLeadInvestigatorId
  pure
    [ CheckWindow
      [leadInvestigatorId]
      [Window Timing.When (ActAdvance $ toId attrs)]
    , chooseOne
      leadInvestigatorId
      [AdvanceAct (toId attrs) (toSource attrs) advanceMode]
    ]

instance RunMessage ActAttrs where
  runMessage msg a@ActAttrs {..} = case msg of
    AdvanceAct aid _ advanceMode | aid == actId && onSide A a -> do
      pushAll =<< advanceActSideA a advanceMode
      pure $ a & (sequenceL .~ Act (unActStep $ actStep actSequence) B)
    AttachTreachery tid (ActTarget aid) | aid == actId ->
      pure $ a & treacheriesL %~ insertSet tid
    Discard (ActTarget aid) | aid == toId a -> do
      pushAll
        [ Discard (TreacheryTarget tid) | tid <- setToList actTreacheries ]
      pure a
    Discard (TreacheryTarget tid) -> pure $ a & treacheriesL %~ deleteSet tid
    InvestigatorResigned _ -> do
      investigatorIds <- select UneliminatedInvestigator
      whenMsg <- checkWindows
        [Window Timing.When AllUndefeatedInvestigatorsResigned]
      afterMsg <- checkWindows
        [Window Timing.When AllUndefeatedInvestigatorsResigned]
      a <$ when
        (null investigatorIds)
        (pushAll [whenMsg, afterMsg, AllInvestigatorsResigned])
    UseCardAbility iid source _ 999 _ | isSource a source ->
      -- This is assumed to be advancement via spending clues
      a <$ push (AdvanceAct (toId a) (InvestigatorSource iid) AdvancedWithClues)
    PlaceClues (ActTarget aid) n | aid == actId -> do
      let totalClues = n + actClues
      pure $ a { actClues = totalClues }
    _ -> pure a

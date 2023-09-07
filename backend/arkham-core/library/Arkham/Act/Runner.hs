{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.Act.Runner (
  module Arkham.Act.Runner,
  module X,
) where

import Arkham.Prelude

import Arkham.Act.Sequence as X
import Arkham.Act.Types as X
import Arkham.Cost as X
import Arkham.GameValue as X
import Arkham.Helpers.Message as X
import Arkham.Helpers.SkillTest as X
import Arkham.Source as X
import Arkham.Target as X

import Arkham.Classes
import Arkham.Game.Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Matcher hiding (FastPlayerWindow)
import Arkham.Message
import Arkham.Timing qualified as Timing
import Arkham.Window
import Arkham.Window qualified as Window

advanceActDeck :: ActAttrs -> Message
advanceActDeck attrs = AdvanceActDeck (actDeckId attrs) (toSource attrs)

advanceActSideA
  :: HasGame m => ActAttrs -> AdvancementMethod -> m [Message]
advanceActSideA attrs advanceMode = do
  leadInvestigatorId <- getLeadInvestigatorId
  pure
    [ CheckWindow
        [leadInvestigatorId]
        [mkWindow Timing.When (ActAdvance $ toId attrs)]
    , chooseOne
        leadInvestigatorId
        [TargetLabel (ActTarget $ toId attrs) [AdvanceAct (toId attrs) (toSource attrs) advanceMode]]
    ]

instance RunMessage Act where
  runMessage msg (Act a) = Act <$> runMessage msg a

instance RunMessage ActAttrs where
  runMessage msg a@ActAttrs {..} = case msg of
    AdvanceAct aid _ advanceMode | aid == actId && onSide A a -> do
      pushAll =<< advanceActSideA a advanceMode
      pure $ a & (sequenceL .~ Sequence (unActStep $ actStep actSequence) B)
    AdvanceAct aid _ advanceMode | aid == actId && onSide C a -> do
      pushAll =<< advanceActSideA a advanceMode
      pure $ a & (sequenceL .~ Sequence (unActStep $ actStep actSequence) D)
    AdvanceAct aid _ advanceMode | aid == actId && onSide E a -> do
      pushAll =<< advanceActSideA a advanceMode
      pure $ a & (sequenceL .~ Sequence (unActStep $ actStep actSequence) F)
    AttachTreachery tid (ActTarget aid)
      | aid == actId ->
          pure $ a & treacheriesL %~ insertSet tid
    Discard _ (ActTarget aid) | aid == toId a -> do
      pushAll
        [Discard GameSource (TreacheryTarget tid) | tid <- setToList actTreacheries]
      pure a
    Discard _ (TreacheryTarget tid) -> pure $ a & treacheriesL %~ deleteSet tid
    InvestigatorResigned _ -> do
      investigatorIds <- select UneliminatedInvestigator
      whenMsg <-
        checkWindows
          [mkWindow Timing.When AllUndefeatedInvestigatorsResigned]
      afterMsg <-
        checkWindows
          [mkWindow Timing.When AllUndefeatedInvestigatorsResigned]
      when
        (null investigatorIds)
        (pushAll [whenMsg, afterMsg, AllInvestigatorsResigned])
      pure a
    UseCardAbility iid source 999 _ _ | isSource a source -> do
      -- This is assumed to be advancement via spending clues
      push $ AdvanceAct (toId a) (InvestigatorSource iid) AdvancedWithClues
      pure a
    PlaceClues _ (ActTarget aid) n | aid == actId -> do
      let totalClues = n + actClues
      pure $ a {actClues = totalClues}
    PlaceBreaches (isTarget a -> True) n -> do
      let total = maybe 0 (+ n) actBreaches
      pure $ a & breachesL ?~ total
    RemoveBreaches (isTarget a -> True) n -> do
      wouldDoEach
        n
        (RemoveBreaches (toTarget a) 1)
        (Window.WouldRemoveBreaches (toTarget a))
        (Window.WouldRemoveBreach (toTarget a))
        (Window.RemovedBreaches (toTarget a))
        (Window.RemovedBreach (toTarget a))
      pure a
    Do (RemoveBreaches (isTarget a -> True) n) -> do
      pure $ a & breachesL %~ fmap (max 0 . subtract n)
    _ -> pure a

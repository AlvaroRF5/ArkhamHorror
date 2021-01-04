module Arkham.Types.ChaosBag
  ( ChaosBag
  , emptyChaosBag
  , tokensL
  )
where

import Arkham.Prelude

import Arkham.Json
import Arkham.Types.ChaosBagStepState
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.InvestigatorId
import Arkham.Types.Message
import Arkham.Types.Query
import Arkham.Types.RequestedTokenStrategy
import Arkham.Types.Source
import Arkham.Types.Token
import Arkham.Types.Window
import Control.Monad.State

isUndecided :: ChaosBagStepState -> Bool
isUndecided (Undecided _) = True
isUndecided _ = False

isResolved :: ChaosBagStepState -> Bool
isResolved (Resolved _) = True
isResolved _ = False

toDecided :: ChaosBagStepState -> ChaosBagStepState
toDecided (Undecided x) = Decided x
toDecided other = other

toTokens :: ChaosBagStepState -> [Token]
toTokens (Resolved tokens') = tokens'
toTokens _ = []

toGroups
  :: [ChaosBagStepState] -> [[Token]] -> [([ChaosBagStepState], [[Token]])]
toGroups steps tokens' = go steps []
 where
  go [] _ = []
  go (step : rest) prev = case step of
    Resolved group' -> (prev <> rest, group' : tokens') : go rest (step : prev)
    _ -> error "must be resolved"

replaceFirstChoice
  :: Source
  -> Maybe InvestigatorId
  -> RequestedTokenStrategy
  -> ChaosBagStep
  -> ChaosBagStepState
  -> ChaosBagStepState
replaceFirstChoice source miid strategy replacement = \case
  Undecided _ -> error "should not be ran with undecided"
  Resolved tokens' -> Resolved tokens'
  Decided step -> case step of
    Draw -> Decided Draw
    Choose n steps tokens' -> if all isResolved steps
      then Decided replacement
      else Decided $ Choose
        n
        (replaceFirstChooseChoice source miid strategy replacement steps)
        tokens'

replaceFirstChooseChoice
  :: Source
  -> Maybe InvestigatorId
  -> RequestedTokenStrategy
  -> ChaosBagStep
  -> [ChaosBagStepState]
  -> [ChaosBagStepState]
replaceFirstChooseChoice source miid strategy replacement = \case
  [] -> []
  (Undecided _ : _) -> error "should not be ran with undecided"
  (Resolved tokens' : rest) ->
    Resolved tokens'
      : replaceFirstChooseChoice source miid strategy replacement rest
  (Decided step : rest) ->
    replaceFirstChoice source miid strategy replacement (Decided step) : rest

resolveFirstUnresolved
  :: ( MonadRandom m
     , MonadState ChaosBag m
     , MonadReader env m
     , HasId LeadInvestigatorId env ()
     )
  => Source
  -> Maybe InvestigatorId
  -> RequestedTokenStrategy
  -> ChaosBagStepState
  -> m (ChaosBagStepState, [Message])
resolveFirstUnresolved source miid strategy = \case
  Undecided _ -> error "should not be ran with undecided"
  Resolved tokens' -> pure (Resolved tokens', [])
  Decided step -> case step of
    Draw -> do
      bagTokens <- gets chaosBagTokens
      (drawn, remaining) <- splitAt 1 <$> shuffleM bagTokens
      modify' ((tokensL .~ remaining) . (setAsideTokensL %~ (drawn <>)))
      pure (Resolved drawn, [])
    Choose n steps tokens' -> if length tokens' == n
      then pure (Resolved $ concat tokens', [])
      else if all isResolved steps
        then if length steps == n
          then pure (Resolved $ concatMap toTokens steps, [])
          else do
            iid <- maybe getLeadInvestigatorId pure miid
            pure
              ( Decided (Choose n steps tokens')
              , [ Ask
                    iid
                    (ChooseOne
                      [ ChooseTokenGroups source iid (Choose n remaining chosen)
                      | (remaining, chosen) <- toGroups steps tokens'
                      ]
                    )
                ]
              )
        else do
          (steps', msgs) <- resolveFirstChooseUnresolved
            source
            miid
            strategy
            steps
          pure (Decided $ Choose n steps' tokens', msgs)

resolveFirstChooseUnresolved
  :: ( MonadRandom m
     , MonadState ChaosBag m
     , MonadReader env m
     , HasId LeadInvestigatorId env ()
     )
  => Source
  -> Maybe InvestigatorId
  -> RequestedTokenStrategy
  -> [ChaosBagStepState]
  -> m ([ChaosBagStepState], [Message])
resolveFirstChooseUnresolved source miid strategy = \case
  [] -> pure ([], [])
  (Undecided _ : _) -> error "should not be called with undecided"
  (Resolved tokens' : rest) -> do
    (rest', msgs) <- resolveFirstChooseUnresolved source miid strategy rest
    pure (Resolved tokens' : rest', msgs)
  (Decided step : rest) -> do
    (step', msgs) <- resolveFirstUnresolved source miid strategy (Decided step)
    pure (step' : rest, msgs)

decideFirstUndecided
  :: Source
  -> Maybe InvestigatorId
  -> RequestedTokenStrategy
  -> (ChaosBagStepState -> ChaosBagStepState)
  -> ChaosBagStepState
  -> (ChaosBagStepState, [Message])
decideFirstUndecided source miid strategy f = \case
  Decided step -> (Decided step, [])
  Resolved tokens' -> (Resolved tokens', [])
  Undecided step -> case step of
    Draw ->
      ( f $ Undecided Draw
      , [ CheckWindow iid [WhenWouldRevealChaosToken source You]
        | iid <- maybeToList miid
        ]
        <> [NextChaosBagStep source miid strategy]
      )
    Choose n steps tokens' -> if any isUndecided steps
      then
        let
          (steps', msgs) =
            decideFirstChooseUndecided source miid strategy f steps
        in (Undecided $ Choose n steps' tokens', msgs)
      else (f $ Undecided (Choose n steps tokens'), [])

decideFirstChooseUndecided
  :: Source
  -> Maybe InvestigatorId
  -> RequestedTokenStrategy
  -> (ChaosBagStepState -> ChaosBagStepState)
  -> [ChaosBagStepState]
  -> ([ChaosBagStepState], [Message])
decideFirstChooseUndecided source miid strategy f = \case
  [] -> ([], [])
  (Decided step : rest) ->
    let (rest', msgs) = decideFirstChooseUndecided source miid strategy f rest
    in (Decided step : rest', msgs)
  (Resolved tokens' : rest) ->
    let (rest', msgs) = decideFirstChooseUndecided source miid strategy f rest
    in (Resolved tokens' : rest', msgs)
  (Undecided step : rest) ->
    let
      (step', msgs) =
        decideFirstUndecided source miid strategy f (Undecided step)
    in (step' : rest, msgs)

data ChaosBag = ChaosBag
  { chaosBagTokens :: [Token]
  , chaosBagSetAsideTokens :: [Token]
  , chaosBagRevealedTokens :: [Token]
  , chaosBagChoice :: Maybe ChaosBagStepState
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON ChaosBag where
  toJSON = genericToJSON $ aesonOptions $ Just "chaosBag"
  toEncoding = genericToEncoding $ aesonOptions $ Just "chaosBag"

instance FromJSON ChaosBag where
  parseJSON = genericParseJSON $ aesonOptions $ Just "chaosBag"

emptyChaosBag :: ChaosBag
emptyChaosBag = ChaosBag
  { chaosBagTokens = []
  , chaosBagSetAsideTokens = []
  , chaosBagRevealedTokens = []
  , chaosBagChoice = Nothing
  }

tokensL :: Lens' ChaosBag [Token]
tokensL = lens chaosBagTokens $ \m x -> m { chaosBagTokens = x }

setAsideTokensL :: Lens' ChaosBag [Token]
setAsideTokensL =
  lens chaosBagSetAsideTokens $ \m x -> m { chaosBagSetAsideTokens = x }

revealedTokensL :: Lens' ChaosBag [Token]
revealedTokensL =
  lens chaosBagRevealedTokens $ \m x -> m { chaosBagRevealedTokens = x }

choiceL :: Lens' ChaosBag (Maybe ChaosBagStepState)
choiceL = lens chaosBagChoice $ \m x -> m { chaosBagChoice = x }

instance HasList Token env ChaosBag where
  getList = pure . chaosBagTokens

instance (HasQueue env, HasId LeadInvestigatorId env ()) => RunMessage env ChaosBag where
  runMessage msg c@ChaosBag {..} = case msg of
    SetTokens tokens' ->
      pure $ c & tokensL .~ tokens' & setAsideTokensL .~ mempty
    ResetTokens _source ->
      pure
        $ c
        & tokensL
        %~ (<> chaosBagSetAsideTokens)
        & setAsideTokensL
        .~ mempty
    RequestTokens source miid n strategy -> do
      unshiftMessage (RunBag source miid strategy)
      case n of
        0 -> pure $ c & revealedTokensL .~ []
        1 -> pure $ c & choiceL ?~ Undecided Draw & revealedTokensL .~ []
        x ->
          pure
            $ c
            & (choiceL ?~ Undecided (Choose x (replicate x (Undecided Draw)) [])
              )
            & (revealedTokensL .~ [])
    RunBag source miid strategy -> case chaosBagChoice of
      Nothing -> error "unexpected"
      Just choice' -> if isUndecided choice'
        then do
          let
            (choice'', msgs) =
              decideFirstUndecided source miid strategy id choice'
          unshiftMessage (RunBag source miid strategy)
          unshiftMessages msgs
          pure $ c & choiceL ?~ choice''
        else c <$ unshiftMessage (RunDrawFromBag source miid strategy)
    NextChaosBagStep source miid strategy -> case chaosBagChoice of
      Nothing -> error "unexpected"
      Just choice' -> do
        let
          (updatedChoice, messages) =
            decideFirstUndecided source miid strategy toDecided choice'
        unless (null messages) $ unshiftMessages messages
        pure $ c & choiceL ?~ updatedChoice
    ReplaceCurrentDraw source iid step -> case chaosBagChoice of
      Nothing -> error "unexpected"
      Just choice' -> do
        let
          (updatedChoice, messages) = decideFirstUndecided
            source
            (Just iid)
            SetAside
            (const (Undecided step))
            choice'
        unless (null messages) $ unshiftMessages messages
        pure $ c & choiceL ?~ updatedChoice
    RunDrawFromBag source miid strategy -> case chaosBagChoice of
      Nothing -> error "unexpected"
      Just choice' -> case choice' of
        Resolved tokenFaces' -> c <$ unshiftMessages
          (FocusTokens tokenFaces'
          : [ CheckWindow
                iid
                [ WhenRevealToken You token | token <- tokenFaces' ]
            | iid <- maybeToList miid
            ]
          <> [RequestedTokens source miid tokenFaces', UnfocusTokens]
          )
        _ -> do
          ((choice'', msgs), c') <- runStateT
            (resolveFirstUnresolved source miid strategy choice')
            c
          unshiftMessage (RunDrawFromBag source miid strategy)
          unshiftMessages msgs
          pure $ c' & choiceL ?~ choice''
    ChooseTokenGroups source iid groupChoice -> case chaosBagChoice of
      Nothing -> error "unexpected"
      Just choice' -> do
        let
          updatedChoice =
            replaceFirstChoice source (Just iid) SetAside groupChoice choice'
        pure $ c & choiceL ?~ updatedChoice
    RevealToken _source _iid token ->
      -- TODO: we may need a map of source to tokens here
      pure $ c & revealedTokensL %~ (token :)
    ReturnTokens tokens' ->
      pure $ c & tokensL %~ (<> tokens') & setAsideTokensL %~ (\\ tokens')
    AddToken token -> pure $ c & tokensL %~ (token :)
    _ -> pure c

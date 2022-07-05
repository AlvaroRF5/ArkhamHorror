module Arkham.ActiveCost where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action hiding ( Ability, TakenAction )
import Arkham.Action qualified as Action
import Arkham.Asset.Attrs ( Field (AssetCard) )
import Arkham.Card
import Arkham.ChaosBag.Base
import Arkham.Classes
import Arkham.Cost hiding ( PaidCost )
import Arkham.Game.Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.ChaosBag
import Arkham.Id
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher hiding ( AssetCard, PlayCard )
import Arkham.Message
import Arkham.Projection
import Arkham.Scenario.Attrs ( Field (..) )
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Arkham.Token
import Arkham.Timing qualified as Timing
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window

data ActiveCost = ActiveCost
  { activeCostId :: ActiveCostId
  , activeCostCosts :: Cost
  , activeCostPayments :: Payment
  , activeCostTarget :: ActiveCostTarget
  , activeCostWindows :: [Window]
  , activeCostInvestigator :: InvestigatorId
  , activeCostSealedTokens :: [Token]
  }
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

data ActiveCostTarget = ForCard Card | ForAbility Ability
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

activeCostAction :: ActiveCost -> Maybe Action
activeCostAction ac = case activeCostTarget ac of
  ForAbility a -> Just $ fromMaybe Action.Ability (abilityAction a)
  ForCard c -> Just $ fromMaybe Action.Play (cdAction $ toCardDef c)

activeCostSource :: ActiveCost -> Source
activeCostSource ac = case activeCostTarget ac of
  ForAbility a -> abilitySource a
  ForCard c -> CardIdSource $ toCardId c

costPaymentsL :: Lens' ActiveCost Payment
costPaymentsL = lens activeCostPayments $ \m x -> m { activeCostPayments = x }

costSealedTokensL :: Lens' ActiveCost [Token]
costSealedTokensL = lens activeCostSealedTokens $ \m x -> m { activeCostSealedTokens = x }

activeCostPaid :: ActiveCost -> Bool
activeCostPaid = (== Free) . activeCostCosts

matchTarget :: [Action] -> ActionTarget -> Action -> Bool
matchTarget takenActions (FirstOneOf as) action =
  action `elem` as && all (`notElem` takenActions) as
matchTarget _ (IsAction a) action = action == a
matchTarget _ (EnemyAction a _) action = action == a

getActionCostModifier :: (Monad m, HasGame m) => ActiveCost -> m Int
getActionCostModifier ac = do
  let iid = activeCostInvestigator ac
  takenActions <- field InvestigatorActionsTaken iid
  modifiers <- getModifiers (InvestigatorSource iid) (InvestigatorTarget iid)
  pure $ foldr (applyModifier takenActions) 0 modifiers
 where
  action = fromJustNote "expected action" $ activeCostAction ac
  applyModifier takenActions (ActionCostOf match m) n =
    if matchTarget takenActions match action then n + m else n
  applyModifier _ _ n = n

countAdditionalActionPayments :: Payment -> Int
countAdditionalActionPayments AdditionalActionPayment = 1
countAdditionalActionPayments (Payments ps) =
  sum $ map countAdditionalActionPayments ps
countAdditionalActionPayments _ = 0

startAbilityPayment
  :: ActiveCost
  -> InvestigatorId
  -> Window
  -> AbilityType
  -> Source
  -> Bool
  -> GameT ()
startAbilityPayment activeCost@ActiveCost { activeCostId } iid window abilityType abilitySource abilityDoesNotProvokeAttacksOfOpportunity
  = case abilityType of
    Objective aType -> startAbilityPayment
      activeCost
      iid
      window
      aType
      abilitySource
      abilityDoesNotProvokeAttacksOfOpportunity
    ForcedAbility _ -> pure ()
    SilentForcedAbility _ -> pure ()
    ForcedAbilityWithCost _ cost -> push (PayCost activeCostId iid False cost)
    AbilityEffect cost -> push (PayCost activeCostId iid False cost)
    FastAbility cost -> push (PayCost activeCostId iid False cost)
    ReactionAbility _ cost -> push (PayCost activeCostId iid False cost)
    ActionAbilityWithBefore mAction _ cost -> do
      -- we do not know which ability will be chosen
      -- for now we assume this will trigger attacks of opportunity
      -- we also skip additional cost checks and abilities of this type
      -- will need to trigger the appropriate check
      pushAll
        (PayCost activeCostId iid True cost
        : [ TakenAction iid action | action <- maybeToList mAction ]
        <> [ CheckAttackOfOpportunity iid False
           | not abilityDoesNotProvokeAttacksOfOpportunity
           ]
        )
    ActionAbilityWithSkill mAction _ cost ->
      if mAction
          `notElem` [ Just Action.Fight
                    , Just Action.Evade
                    , Just Action.Resign
                    , Just Action.Parley
                    ]
        then pushAll
          (PayCost activeCostId iid False cost
          : [ TakenAction iid action | action <- maybeToList mAction ]
          <> [ CheckAttackOfOpportunity iid False
             | not abilityDoesNotProvokeAttacksOfOpportunity
             ]
          )
        else pushAll
          (PayCost activeCostId iid False cost
          : [ TakenAction iid action | action <- maybeToList mAction ]
          )
    ActionAbility mAction cost -> do
      let action = fromMaybe Action.Ability $ mAction
      beforeWindowMsg <- checkWindows
        [Window Timing.When (Window.PerformAction iid action)]
      if action
        `notElem` [Action.Fight, Action.Evade, Action.Resign, Action.Parley]
      then
        pushAll
          ([ BeginAction
           , beforeWindowMsg
           , PayCost activeCostId iid False cost
           , TakenAction iid action
           ]
          <> [ CheckAttackOfOpportunity iid False
             | not abilityDoesNotProvokeAttacksOfOpportunity
             ]
          )
      else
        pushAll
          $ [ BeginAction
            , beforeWindowMsg
            , PayCost activeCostId iid False cost
            , TakenAction iid action
            ]

nonAttackOfOpportunityActions :: [Action]
nonAttackOfOpportunityActions =
  [Action.Fight, Action.Evade, Action.Resign, Action.Parley]

instance RunMessage ActiveCost where
  runMessage msg c = case msg of
    CreatedCost acId | acId == activeCostId c -> do
      let iid = activeCostInvestigator c
      case activeCostTarget c of
        ForCard card -> do
          modifiers' <- getModifiers
            (InvestigatorSource iid)
            (InvestigatorTarget iid)
          let
            cardDef = toCardDef card
            modifiersPreventAttackOfOpportunity =
              ActionDoesNotCauseAttacksOfOpportunity Action.Play
                `elem` modifiers'
            action = fromMaybe Action.Play (cdAction cardDef)

          beforeWindowMsg <- checkWindows
            [Window Timing.When (Window.PerformAction iid action)]
          pushAll
            $ [ BeginAction
              , beforeWindowMsg
              , PayCost acId iid False (activeCostCosts c)
              , TakenAction iid action
              ]
            <> [ CheckAttackOfOpportunity iid False
               | not modifiersPreventAttackOfOpportunity
                 && (DoesNotProvokeAttacksOfOpportunity
                    `notElem` (cdAttackOfOpportunityModifiers cardDef)
                    )
                 && (isNothing $ cdFastWindow cardDef)
                 && (action `notElem` nonAttackOfOpportunityActions)
               ]
            <> [PayCostFinished acId]
          pure c
        ForAbility a@Ability {..} -> do
          modifiers' <- getModifiers
            (InvestigatorSource iid)
            (InvestigatorTarget iid)
          let
            modifiersPreventAttackOfOpportunity = maybe
              False
              ((`elem` modifiers') . ActionDoesNotCauseAttacksOfOpportunity)
              (abilityAction a)
          push $ PayCostFinished acId
          startAbilityPayment
            c
            iid
            (Window Timing.When Window.NonFast) -- TODO: a thing
            abilityType
            abilitySource
            (abilityDoesNotProvokeAttacksOfOpportunity
            || modifiersPreventAttackOfOpportunity
            )
          pure c
    PayCost acId iid skipAdditionalCosts cost | acId == activeCostId c -> do
      let
        withPayment payment = pure $ c & costPaymentsL <>~ payment
        source = activeCostSource c
        action = fromJustNote "expected action" $ activeCostAction c
      case cost of
        Costs xs ->
          c <$ pushAll [ PayCost acId iid skipAdditionalCosts x | x <- xs ]
        UpTo 0 _ -> pure c
        UpTo n cost' -> do
          canAfford <- getCanAffordCost iid source (Just action) [] cost'
          c <$ when
            canAfford
            (push $ Ask iid $ ChoosePaymentAmounts
              ("Pay " <> displayCostType cost)
              Nothing
              [(iid, (0, n), PayCost acId iid skipAdditionalCosts cost')]
            )
            --   iid
            --   [ Label
            --     "Pay dynamic cost"
            --     [ PayCost source iid mAction skipAdditionalCosts cost'
            --     , PayCost
            --       source
            --       iid
            --       mAction
            --       skipAdditionalCosts
            --       (UpTo (n - 1) cost')
            --     ]
            --   , Label "Done with dynamic cost" []
            --   ]
            -- )
        ExhaustCost target -> do
          push (Exhaust target)
          withPayment $ ExhaustPayment [target]
        ExhaustAssetCost matcher -> do
          targets <- map AssetTarget <$> selectList (matcher <> AssetReady)
          c <$ push
            (chooseOne
              iid
              [ TargetLabel
                  target
                  [PayCost acId iid skipAdditionalCosts (ExhaustCost target)]
              | target <- targets
              ]
            )
        SealCost matcher -> do
          targets <-
            filterM (\t -> matchToken iid t matcher)
              =<< scenarioFieldMap ScenarioChaosBag chaosBagTokens
          pushAll
            [ FocusTokens targets
            , chooseOne
              iid
              [ TargetLabel
                  (TokenTarget target)
                  [PayCost acId iid skipAdditionalCosts (SealTokenCost target)]
              | target <- targets
              ]
            , UnfocusTokens
            ]
          pure c
        SealTokenCost token -> do
          push $ SealToken token
          pure $ c & costPaymentsL <>~ SealTokenPayment token & costSealedTokensL %~ (token :)
        DiscardCost target -> do
          pushAll [DiscardedCost target, Discard target]
          withPayment $ DiscardPayment [target]
        DiscardCardCost card -> do
          push (DiscardCard iid (toCardId card))
          withPayment $ DiscardCardPayment [card]
        DiscardDrawnCardCost -> do
          let
            getDrawnCard [] = error "can not find drawn card in windows"
            getDrawnCard (x : xs) = case x of
              Window _ (Window.DrawCard _ card' _) -> card'
              _ -> getDrawnCard xs
            card = getDrawnCard (activeCostWindows c)
          push (DiscardCard iid (toCardId card))
          withPayment $ DiscardCardPayment [card]
        ExileCost target -> do
          push (Exile target)
          withPayment $ ExilePayment [target]
        RemoveCost target -> do
          push (RemoveFromGame target)
          withPayment $ RemovePayment [target]
        DoomCost _ (AgendaMatcherTarget matcher) x -> do
          agendas <- selectListMap AgendaTarget matcher
          pushAll [ PlaceDoom target x | target <- agendas ]
          withPayment $ DoomPayment (x * length agendas)
        DoomCost _ target x -> do
          push (PlaceDoom target x)
          withPayment $ DoomPayment x
        HorrorCost _ target x -> case target of
          InvestigatorTarget iid' | iid' == iid -> do
            push (InvestigatorAssignDamage iid source DamageAny 0 x)
            withPayment $ HorrorPayment x
          YouTarget -> do
            push (InvestigatorAssignDamage iid source DamageAny 0 x)
            withPayment $ HorrorPayment x
          AssetTarget aid -> do
            pushAll [AssetDamage aid source 0 x, CheckDefeated source]
            withPayment $ HorrorPayment x
          _ -> error "can't target for horror cost"
        DamageCost _ target x -> case target of
          InvestigatorTarget iid' | iid' == iid -> do
            push (InvestigatorAssignDamage iid source DamageAny x 0)
            withPayment $ DamagePayment x
          YouTarget -> do
            push (InvestigatorAssignDamage iid source DamageAny x 0)
            withPayment $ DamagePayment x
          AssetTarget aid -> do
            pushAll [AssetDamage aid source x 0, CheckDefeated source]
            withPayment $ DamagePayment x
          _ -> error "can't target for damage cost"
        DirectDamageCost _ investigatorMatcher x -> do
          investigators <- selectList investigatorMatcher
          case investigators of
            [iid'] -> do
              push $ InvestigatorDirectDamage iid' source x 0
              withPayment $ DirectDamagePayment x
            _ -> error "exactly one investigator expected for direct damage"
        InvestigatorDamageCost _ investigatorMatcher damageStrategy x -> do
          investigators <- selectList investigatorMatcher
          push $ chooseOne
            iid
            [ targetLabel
                iid'
                [InvestigatorAssignDamage iid' source damageStrategy x 0]
            | iid' <- investigators
            ]
          withPayment $ InvestigatorDamagePayment x
        ResourceCost x -> do
          push (SpendResources iid x)
          withPayment $ ResourcePayment x
        AdditionalActionsCost -> do
          actionRemainingCount <- field InvestigatorRemainingActions iid
          let
            currentlyPaid =
              countAdditionalActionPayments (activeCostPayments c)
          c <$ if actionRemainingCount == 0
            then pure ()
            else push
              (chooseOne
                iid
                [ Label
                  "Spend 1 additional action"
                  [ PayCost acId iid skipAdditionalCosts (ActionCost 1)
                  , PaidAbilityCost iid Nothing AdditionalActionPayment
                  , msg
                  ]
                , Label
                  ("Done spending additional actions ("
                  <> tshow currentlyPaid
                  <> " spent so far)"
                  )
                  []
                ]
              )
        ActionCost x -> do
          costModifier <- if skipAdditionalCosts
            then pure 0
            else getActionCostModifier c
          let modifiedActionCost = max 0 (x + costModifier)
          push (SpendActions iid source modifiedActionCost)
          withPayment $ ActionPayment x
        UseCost assetMatcher uType n -> do
          assets <- selectList assetMatcher
          push $ chooseOrRunOne
            iid
            [ TargetLabel
                (AssetTarget aid)
                [SpendUses (AssetTarget aid) uType n]
            | aid <- assets
            ]
          withPayment $ UsesPayment n
        ClueCost x -> do
          push (InvestigatorSpendClues iid x)
          withPayment $ CluePayment x
        PlaceClueOnLocationCost x -> do
          push (InvestigatorPlaceCluesOnLocation iid x)
          withPayment $ CluePayment x
        GroupClueCost x locationMatcher -> do
          totalClues <- getPlayerCountValue x
          iids <-
            selectList
            $ InvestigatorAt locationMatcher
            <> InvestigatorWithAnyClues
          iidsWithClues <-
            filter ((> 0) . snd)
              <$> traverse (traverseToSnd (getSpendableClueCount . pure)) iids
          case iidsWithClues of
            [(iid', _)] ->
              c <$ push (PayCost acId iid' True (ClueCost totalClues))
            _ -> do
              let
                paymentOptions = map
                  (\(iid', clues) ->
                    (iid', (0, clues), PayCost acId iid' True (ClueCost 1))
                  )
                  iidsWithClues
              leadInvestigatorId <- getLeadInvestigatorId
              c <$ push
                (Ask leadInvestigatorId $ ChoosePaymentAmounts
                  (displayCostType cost)
                  (Just totalClues)
                  paymentOptions
                )
          -- push (SpendClues totalClues iids)
          -- withPayment $ CluePayment totalClues
        HandDiscardCost x cardMatcher -> do
          handCards <- fieldMap
            InvestigatorHand
            (mapMaybe (preview _PlayerCard))
            iid
          let cards = filter (`cardMatch` cardMatcher) handCards
          push $ chooseN
            iid
            x
            [ TargetLabel
                (CardIdTarget $ toCardId card)
                [ PayCost
                    acId
                    iid
                    skipAdditionalCosts
                    (DiscardCardCost $ PlayerCard card)
                ]
            | card <- cards
            ]
          pure c
        DiscardFromCost x zone cardMatcher -> do
          let
            getCards = \case
              FromHandOf whoMatcher ->
                selectList (InHandOf whoMatcher <> BasicCardMatch cardMatcher)
              FromPlayAreaOf whoMatcher -> do
                assets <- selectList $ AssetControlledBy whoMatcher
                traverse (field AssetCard) assets
              CostZones zs -> concatMapM getCards zs
          cards <- getCards zone
          c <$ push
            (chooseN
              iid
              x
              [ TargetLabel
                  (CardIdTarget $ toCardId card)
                  [ PayCost
                      acId
                      iid
                      skipAdditionalCosts
                      (DiscardCost $ CardIdTarget $ toCardId card)
                  ]
              | card <- cards
              ]
            )
        SkillIconCost x skillTypes -> do
          handCards <- fieldMap
            InvestigatorHand
            (mapMaybe (preview _PlayerCard))
            iid
          let
            cards = filter ((> 0) . fst) $ map
              (toFst
                (count (`member` insertSet SkillWild skillTypes)
                . cdSkills
                . toCardDef
                )
              )
              handCards
            cardMsgs = map
              (\(n, card) -> if n >= x
                then Run
                  [ DiscardCard iid (toCardId card)
                  , PaidAbilityCost
                    iid
                    Nothing
                    (SkillIconPayment $ cdSkills $ toCardDef card)
                  ]
                else Run
                  [ DiscardCard iid (toCardId card)
                  , PaidAbilityCost
                    iid
                    Nothing
                    (SkillIconPayment $ cdSkills $ toCardDef card)
                  , PayCost
                    acId
                    iid
                    skipAdditionalCosts
                    (SkillIconCost (x - n) skillTypes)
                  ]
              )
              cards
          c <$ push (chooseOne iid cardMsgs)
        Free -> pure c
    PaidCost acId _ _ payment | acId == activeCostId c ->
      pure $ c & costPaymentsL <>~ payment
    PayCostFinished acId | acId == activeCostId c -> do
      case activeCostTarget c of
        ForAbility ability -> do
          let
            action = fromMaybe Action.Ability (abilityAction ability)
            iid = activeCostInvestigator c
          whenActivateAbilityWindow <- checkWindows
            [Window Timing.When (Window.ActivateAbility iid ability)]
          afterWindowMsgs <- checkWindows
            [Window Timing.After (Window.PerformAction iid action)]
          pushAll
            $ [ whenActivateAbilityWindow
              , UseCardAbility
                iid
                (abilitySource ability)
                (activeCostWindows c)
                (abilityIndex ability)
                (activeCostPayments c)
              , ClearDiscardCosts
              ]
            <> [afterWindowMsgs, FinishAction]
        ForCard card -> do
          let iid = activeCostInvestigator c
          pushAll $ [PlayCard iid card Nothing False] <> [SealedToken token card | token <- activeCostSealedTokens c] <> [FinishAction]
      pure c
    _ -> pure c

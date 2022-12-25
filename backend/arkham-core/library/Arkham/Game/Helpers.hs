module Arkham.Game.Helpers
  ( module Arkham.Game.Helpers
  , module X
  ) where

import Arkham.Prelude

import Arkham.Helpers.Ability as X
import Arkham.Helpers.EncounterSet as X
import Arkham.Helpers.Log as X
import Arkham.Helpers.Modifiers as X
import Arkham.Helpers.Query as X
import Arkham.Helpers.Scenario as X
import Arkham.Helpers.Slot as X
import Arkham.Helpers.Window as X
import Arkham.Helpers.Xp as X

import Arkham.Ability
import Arkham.Act.Sequence qualified as AS
import Arkham.Act.Types ( Field (..) )
import Arkham.Action ( Action )
import Arkham.Action qualified as Action
import Arkham.Action.Additional
import Arkham.Agenda.Types ( Field (..) )
import Arkham.Asset.Types ( Field (..) )
import Arkham.Asset.Uses ( useTypeCount )
import Arkham.Attack
import Arkham.Card
import Arkham.Card.Cost
import Arkham.ChaosBag.Base
import Arkham.ClassSymbol
import Arkham.Classes
import Arkham.Cost
import Arkham.Cost.FieldCost
import Arkham.Criteria ( Criterion )
import Arkham.Criteria qualified as Criteria
import Arkham.DamageEffect
import Arkham.Deck hiding ( InvestigatorDiscard )
import Arkham.DefeatedBy
import Arkham.Enemy.Types ( Field (..) )
import Arkham.Event.Types ( Field (..) )
import {-# SOURCE #-} Arkham.Game
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.GameValue
import Arkham.Helpers
import Arkham.Helpers.Investigator ( baseSkillValueFor )
import Arkham.Id
import Arkham.Investigator.Types ( Field (..), InvestigatorAttrs (..) )
import Arkham.Keyword qualified as Keyword
import Arkham.Location.Types hiding ( location )
import Arkham.Matcher qualified as Matcher
import Arkham.Message hiding ( AssetDamage, InvestigatorDamage, PaidCost )
import Arkham.Name
import Arkham.Phase
import Arkham.Placement
import Arkham.Projection
import Arkham.Query
import Arkham.Scenario.Types ( Field (..) )
import Arkham.Skill.Types ( Field (..) )
import Arkham.SkillTest.Base
import Arkham.SkillTestResult
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Token
import Arkham.Trait ( Trait, toTraits )
import Arkham.Treachery.Types ( Field (..) )
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window
import Control.Monad.Reader ( local )
import Data.HashSet qualified as HashSet

replaceThisCard :: Card -> Source -> Source
replaceThisCard c = \case
  ThisCard -> CardCostSource (toCardId c)
  s -> s

cancelToken :: Token -> GameT ()
cancelToken token = withQueue $ \queue ->
  ( filter
    (\case
      When (RevealToken _ _ token') | token == token' -> False
      RevealToken _ _ token' | token == token' -> False
      After (RevealToken _ _ token') | token == token' -> False
      RequestedTokens _ _ [token'] | token == token' -> False
      RequestedTokens{} -> error "not setup for multiple tokens"
      _ -> True
    )
    queue
  , ()
  )

getPlayableCards
  :: (HasCallStack, Monad m, HasGame m)
  => InvestigatorAttrs
  -> CostStatus
  -> [Window]
  -> m [Card]
getPlayableCards a@InvestigatorAttrs {..} costStatus windows' = do
  asIfInHandCards <- getAsIfInHandCards a
  playableDiscards <- getPlayableDiscards a costStatus windows'
  playableHandCards <- filterM
    (getIsPlayable (toId a) (toSource a) costStatus windows')
    (investigatorHand <> asIfInHandCards)
  pure $ playableHandCards <> playableDiscards

getPlayableDiscards
  :: (Monad m, HasGame m)
  => InvestigatorAttrs
  -> CostStatus
  -> [Window]
  -> m [Card]
getPlayableDiscards attrs@InvestigatorAttrs {..} costStatus windows' = do
  modifiers <- getModifiers (toTarget attrs)
  filterM
    (getIsPlayable (toId attrs) (toSource attrs) costStatus windows')
    (possibleCards modifiers)
 where
  possibleCards modifiers = map (PlayerCard . snd) $ filter
    (canPlayFromDiscard modifiers)
    (zip @_ @Int [0 ..] investigatorDiscard)
  canPlayFromDiscard modifiers (n, card) =
    cdPlayableFromDiscard (toCardDef card)
      || any (allowsPlayFromDiscard n card) modifiers
  allowsPlayFromDiscard 0 card (CanPlayTopOfDiscard (mcardType, traits)) =
    maybe True (== cdCardType (toCardDef card)) mcardType
      && (null traits
         || (setFromList traits `HashSet.isSubsetOf` toTraits (toCardDef card)
            )
         )
  allowsPlayFromDiscard _ _ _ = False

getAsIfInHandCards :: (Monad m, HasGame m) => InvestigatorAttrs -> m [Card]
getAsIfInHandCards attrs = do
  modifiers <- getModifiers (toTarget attrs)
  let
    modifiersPermitPlayOfDiscard c =
      any (modifierPermitsPlayOfDiscard c) modifiers
    modifierPermitsPlayOfDiscard (c, depth) = \case
      CanPlayTopOfDiscard (mType, traits) | depth == 0 ->
        maybe True (== toCardType c) mType
          && (null traits || notNull
               (setFromList traits `intersection` toTraits c)
             )
      _ -> False
    modifiersPermitPlayOfDeck c = any (modifierPermitsPlayOfDeck c) modifiers
    modifierPermitsPlayOfDeck (c, depth) = \case
      CanPlayTopOfDeck cardMatcher | depth == 0 -> cardMatch c cardMatcher
      _ -> False
    cardsAddedViaModifiers = flip mapMaybe modifiers $ \case
      AsIfInHand c -> Just c
      _ -> Nothing
  pure
    $ map
        (PlayerCard . fst)
        (filter
          modifiersPermitPlayOfDiscard
          (zip (investigatorDiscard attrs) [0 :: Int ..])
        )
    <> map
         (PlayerCard . fst)
         (filter
           modifiersPermitPlayOfDeck
           (zip (unDeck $ investigatorDeck attrs) [0 :: Int ..])
         )
    <> cardsAddedViaModifiers

getCanPerformAbility
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> Window
  -> Ability
  -> m Bool
getCanPerformAbility !iid !source !window !ability = do
-- can perform an ability means you can afford it
-- it is in the right window
-- passes restrictions
  abilityModifiers <- getModifiers (AbilityTarget iid ability)
  let
    mAction = case abilityType ability of
      ActionAbilityWithBefore _ mBeforeAction _ -> mBeforeAction
      _ -> abilityAction ability
    additionalCosts = flip mapMaybe abilityModifiers $ \case
      AdditionalCost x -> Just x
      _ -> Nothing
    cost = abilityCost ability
  andM
    [ getCanAffordCost iid (abilitySource ability) mAction [window] cost
    , meetsActionRestrictions iid window ability
    , windowMatches iid source window (abilityWindow ability)
    , maybe
      (pure True)
      (passesCriteria iid (abilitySource ability) [window])
      (abilityCriteria ability)
    , allM
      (getCanAffordCost iid (abilitySource ability) mAction [window])
      additionalCosts
    , not <$> preventedByInvestigatorModifiers iid ability
    ]

preventedByInvestigatorModifiers
  :: (Monad m, HasGame m) => InvestigatorId -> Ability -> m Bool
preventedByInvestigatorModifiers iid ability = do
  modifiers <- getModifiers (InvestigatorTarget iid)
  anyM prevents modifiers
 where
  prevents = \case
    CannotTakeAction x -> preventsAbility x
    _ -> pure False
  preventsAbility = \case
    FirstOneOf as -> case abilityAction ability of
      Just action | action `elem` as ->
        fieldP InvestigatorActionsTaken (\taken -> all (`notElem` taken) as) iid
      _ -> pure False
    IsAction a -> pure $ abilityAction ability == Just a
    EnemyAction a matcher -> case abilitySource ability of
      EnemySource eid ->
        if abilityAction ability == Just a then eid <=~> matcher else pure False
      _ -> pure False

meetsActionRestrictions
  :: (Monad m, HasGame m) => InvestigatorId -> Window -> Ability -> m Bool
meetsActionRestrictions iid _ ab@Ability {..} = go abilityType
 where
  go = \case
    Objective aType -> go aType
    ActionAbilityWithBefore _ mBeforeAction cost ->
      go $ ActionAbility mBeforeAction cost
    ActionAbilityWithSkill mAction _ cost -> go $ ActionAbility mAction cost
    ActionAbility (Just action) _ -> do
      isTurn <- matchWho iid iid Matcher.TurnInvestigator
      if not isTurn
        then pure False
        else case action of
          Action.Fight -> case abilitySource of
            EnemySource _ -> pure True
            _ -> do
              modifiers <- getModifiers (AbilityTarget iid ab)
              let
                isOverride = \case
                  EnemyFightActionCriteria override -> Just override
                  _ -> Nothing
                overrides = mapMaybe isOverride modifiers
              case overrides of
                [] -> notNull <$> select Matcher.CanFightEnemy
                [o] -> notNull <$> select (Matcher.CanFightEnemyWithOverride o)
                _ -> error "multiple overrides found"
          Action.Evade -> case abilitySource of
            EnemySource _ -> pure True
            _ -> notNull <$> select Matcher.CanEvadeEnemy
          Action.Engage -> case abilitySource of
            EnemySource _ -> pure True
            _ -> notNull <$> select Matcher.CanEngageEnemy
          Action.Parley -> case abilitySource of
            EnemySource _ -> pure True
            AssetSource _ -> pure True
            _ -> notNull <$> select (Matcher.CanParleyEnemy iid)
          Action.Investigate -> case abilitySource of
            LocationSource _ -> pure True
            _ -> notNull <$> select Matcher.InvestigatableLocation
          -- The below actions may not be handled correctly yet
          Action.Ability -> pure True
          Action.Draw -> pure True
          Action.Move -> pure True
          Action.Play -> pure True
          Action.Resign -> pure True
          Action.Resource -> pure True
          Action.Explore ->
            iid <=~> Matcher.InvestigatorWithoutModifier CannotExplore
    ActionAbility Nothing _ -> matchWho iid iid Matcher.TurnInvestigator
    FastAbility _ -> pure True
    ReactionAbility _ _ -> pure True
    ForcedAbility _ -> pure True
    SilentForcedAbility _ -> pure True
    ForcedAbilityWithCost _ _ -> pure True
    AbilityEffect _ -> pure True

getCanAffordAbility
  :: (Monad m, HasGame m) => InvestigatorId -> Ability -> Window -> m Bool
getCanAffordAbility iid ability window =
  (&&)
    <$> (getCanAffordUse iid ability window)
    <*> (getCanAffordAbilityCost iid ability)

getCanAffordAbilityCost
  :: (Monad m, HasGame m) => InvestigatorId -> Ability -> m Bool
getCanAffordAbilityCost iid Ability {..} = case abilityType of
  ActionAbility mAction cost ->
    getCanAffordCost iid abilitySource mAction [] cost
  ActionAbilityWithSkill mAction _ cost ->
    getCanAffordCost iid abilitySource mAction [] cost
  ActionAbilityWithBefore _ mBeforeAction cost ->
    getCanAffordCost iid abilitySource mBeforeAction [] cost
  ReactionAbility _ cost -> getCanAffordCost iid abilitySource Nothing [] cost
  FastAbility cost -> getCanAffordCost iid abilitySource Nothing [] cost
  ForcedAbilityWithCost _ cost ->
    getCanAffordCost iid abilitySource Nothing [] cost
  ForcedAbility _ -> pure True
  SilentForcedAbility _ -> pure True
  AbilityEffect _ -> pure True
  Objective{} -> pure True

filterDepthSpecificAbilities
  :: (Monad m, HasGame m) => [UsedAbility] -> m [UsedAbility]
filterDepthSpecificAbilities usedAbilities = do
  depth <- getWindowDepth
  pure $ filter (valid depth) usedAbilities
 where
  valid depth ability =
    abilityLimitType (abilityLimit $ usedAbility ability)
      /= Just PerWindow
      || depth
      <= usedDepth ability

-- TODO: The limits that are correct are the one that check usedTimes Group
-- limits for instance won't work if we have a group limit higher than one, for
-- that we need to sum uses across all investigators. So we should fix this
-- soon.
getCanAffordUse
  :: (Monad m, HasGame m) => InvestigatorId -> Ability -> Window -> m Bool
getCanAffordUse iid ability window = do
  usedAbilities <-
    filterDepthSpecificAbilities =<< field InvestigatorUsedAbilities iid
  case abilityLimit ability of
    NoLimit -> case abilityType ability of
      ReactionAbility _ _ ->
        pure $ notElem ability (map usedAbility usedAbilities)
      ForcedAbility _ -> pure $ notElem ability (map usedAbility usedAbilities)
      SilentForcedAbility _ ->
        pure $ notElem ability (map usedAbility usedAbilities)
      ForcedAbilityWithCost _ _ ->
        pure $ notElem ability (map usedAbility usedAbilities)
      ActionAbility _ _ -> pure True
      ActionAbilityWithBefore{} -> pure True
      ActionAbilityWithSkill{} -> pure True
      FastAbility _ -> pure True
      AbilityEffect _ -> pure True
      Objective{} -> pure True
    PlayerLimit (PerSearch trait) n -> do
      traitMatchingUsedAbilities <- filterM
        (fmap (elem trait) . sourceTraits . abilitySource . usedAbility)
        usedAbilities
      let usedCount = sum $ map usedTimes traitMatchingUsedAbilities
      pure $ usedCount < n
    PlayerLimit _ n -> pure . (< n) . maybe 0 usedTimes $ find
      ((== ability) . usedAbility)
      usedAbilities
    PerCopyLimit cardDef _ n -> do
      let
        abilityCardDef = \case
          PerCopyLimit cDef _ _ -> Just cDef
          _ -> Nothing
      pure . (< n) . getSum . foldMap (Sum . usedTimes) $ filter
        ((Just cardDef ==) . abilityCardDef . abilityLimit . usedAbility)
        usedAbilities
    PerInvestigatorLimit _ n -> do
      -- This is difficult and based on the window, so we need to match out the
      -- relevant investigator ids from the window. If this becomes more prevalent
      -- we may want a method from `Window -> Maybe InvestigatorId`
      case window of
        Window _ (Window.CommittedCards iid' _) -> do
          let
            matchingPerInvestigatorCount =
              flip count usedAbilities $ \usedAbility ->
                flip any (usedAbilityWindows usedAbility) $ \case
                  Window _ (Window.CommittedCard iid'' _) -> iid' == iid''
                  _ -> False
          pure $ matchingPerInvestigatorCount < n
        _ -> error "Unhandled per investigator limit"
    GroupLimit _ n -> do
      usedAbilities' <-
        fmap (map usedAbility)
        . filterDepthSpecificAbilities
        =<< concatMapM (field InvestigatorUsedAbilities)
        =<< allInvestigatorIds
      let total = count (== ability) usedAbilities'
      pure $ total < n

applyActionCostModifier
  :: [Action] -> Maybe Action -> ModifierType -> Int -> Int
applyActionCostModifier _ (Just action) (ActionCostOf (IsAction action') m) n
  | action == action' = n + m
applyActionCostModifier takenActions (Just action) (ActionCostOf (FirstOneOf as) m) n
  | action `elem` as && all (`notElem` takenActions) as
  = n + m
applyActionCostModifier _ _ (ActionCostModifier m) n = n + m
applyActionCostModifier _ _ _ n = n

getCanAffordCost
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> Maybe Action
  -> [Window]
  -> Cost
  -> m Bool
getCanAffordCost iid source mAction windows' = \case
  Free -> pure True
  UpTo{} -> pure True
  DiscardHandCost{} -> pure True
  DiscardTopOfDeckCost{} -> pure True
  AdditionalActionsCost{} -> pure True
  Costs xs ->
    and <$> traverse (getCanAffordCost iid source mAction windows') xs
  OrCost xs ->
    or <$> traverse (getCanAffordCost iid source mAction windows') xs
  ExhaustCost target -> case target of
    AssetTarget aid -> do
      readyAssetIds <- selectList Matcher.AssetReady
      pure $ aid `elem` readyAssetIds
    EventTarget eid -> do
      readyEventIds <- selectList Matcher.EventReady
      pure $ eid `elem` readyEventIds
    _ -> error $ "Not handled" <> show target
  ExhaustAssetCost matcher ->
    notNull <$> select (matcher <> Matcher.AssetReady)
  UseCost assetMatcher uType n -> do
    assets <- selectList assetMatcher
    uses <-
      sum <$> traverse (fmap (useTypeCount uType) . field AssetUses) assets
    pure $ uses >= n
  DynamicUseCost assetMatcher uType useCost -> case useCost of
    DrawnCardsValue -> do
      let
        toDrawnCards = \case
          Window _ (Window.DrawCards _ xs) -> length xs
          _ -> 0
        drawnCardsValue = sum $ map toDrawnCards windows'
      assets <- selectList assetMatcher
      uses <-
        sum <$> traverse (fmap (useTypeCount uType) . field AssetUses) assets
      pure $ uses >= drawnCardsValue
  UseCostUpTo assetMatcher uType n _ -> do
    assets <- selectList assetMatcher
    uses <-
      sum <$> traverse (fmap (useTypeCount uType) . field AssetUses) assets
    pure $ uses >= n
  ActionCost n -> do
    modifiers <- getModifiers (InvestigatorTarget iid)
    if ActionsAreFree `elem` modifiers
      then pure True
      else do
        takenActions <- field InvestigatorActionsTaken iid
        let
          modifiedActionCost =
            foldr (applyActionCostModifier takenActions mAction) n modifiers
        additionalActions <- field InvestigatorAdditionalActions iid
        additionalActionCount <-
          length
            <$> filterM
                  (additionalActionCovers source mAction)
                  additionalActions
        actionCount <- field InvestigatorRemainingActions iid
        pure $ (actionCount + additionalActionCount) >= modifiedActionCost
  ClueCost n -> do
    spendableClues <- getSpendableClueCount [iid]
    pure $ spendableClues >= n
  PerPlayerClueCost n -> do
    spendableClues <- getSpendableClueCount [iid]
    totalClueCost <- getPlayerCountValue (PerPlayer n)
    pure $ spendableClues >= totalClueCost
  PlaceClueOnLocationCost n -> do
    spendableClues <- getSpendableClueCount [iid]
    pure $ spendableClues >= n
  GroupClueCost n locationMatcher -> do
    cost <- getPlayerCountValue n
    iids <- selectList $ Matcher.InvestigatorAt locationMatcher
    totalSpendableClues <- getSpendableClueCount iids
    pure $ totalSpendableClues >= cost
  ResourceCost n -> fieldP InvestigatorResources (>= n) iid
  DiscardFromCost n zone cardMatcher -> do
    -- We need to check that n valid candidates exist across all zones
    -- the logic is that we'll grab all card defs from each zone and then
    -- filter
    let
      getCards = \case
        FromHandOf whoMatcher ->
          fmap (filter (`cardMatch` cardMatcher) . concat)
            . traverse (field InvestigatorHand)
            =<< selectList whoMatcher
        FromPlayAreaOf whoMatcher -> do
          assets <- selectList $ Matcher.AssetControlledBy whoMatcher
          traverse (field AssetCard) assets
        CostZones zs -> concatMapM getCards zs
    (> n) . length <$> getCards zone
  DiscardCost _ -> pure True -- TODO: Make better
  DiscardCardCost _ -> pure True -- TODO: Make better
  DiscardDrawnCardCost -> pure True -- TODO: Make better
  ExileCost _ -> pure True -- TODO: Make better
  RemoveCost _ -> pure True -- TODO: Make better
  HorrorCost{} -> pure True -- TODO: Make better
  DamageCost{} -> pure True -- TODO: Make better
  DirectDamageCost{} -> pure True -- TODO: Make better
  InvestigatorDamageCost{} -> pure True -- TODO: Make better
  DoomCost{} -> pure True -- TODO: Make better
  EnemyDoomCost _ enemyMatcher -> selectAny enemyMatcher
  SkillIconCost n skillTypes -> do
    handCards <- mapMaybe (preview _PlayerCard) <$> field InvestigatorHand iid
    let
      total = sum $ map
        (count (`member` insertSet WildIcon skillTypes) . cdSkills . toCardDef)
        handCards
    pure $ total >= n
  DiscardCombinedCost n -> do
    handCards <-
      mapMaybe (preview _PlayerCard)
      . filter (`cardMatch` Matcher.NonWeakness)
      <$> field InvestigatorHand iid
    let
      total = sum $ map (maybe 0 toPrintedCost . cdCost . toCardDef) handCards
    pure $ total >= n
  ShuffleDiscardCost n cardMatcher -> do
    discards <- fieldMap
      InvestigatorDiscard
      (filter (`cardMatch` cardMatcher))
      iid
    pure $ length discards >= n
  HandDiscardCost n cardMatcher -> do
    cards <- mapMaybe (preview _PlayerCard) <$> field InvestigatorHand iid
    pure $ length (filter (`cardMatch` cardMatcher) cards) >= n
  ReturnMatchingAssetToHandCost assetMatcher -> selectAny assetMatcher
  ReturnAssetToHandCost assetId -> selectAny $ Matcher.AssetWithId assetId
  SealCost tokenMatcher -> do
    tokens <- scenarioFieldMap ScenarioChaosBag chaosBagTokens
    anyM (\token -> matchToken iid token tokenMatcher) tokens
  SealTokenCost _ -> pure True
  ReleaseTokensCost n -> do
    case source of
      AssetSource aid -> fieldMap AssetSealedTokens ((>= n) . length) aid 
      _ -> error "Unhandled release token cost source"
  ReleaseTokenCost t -> do
    case source of
      AssetSource aid -> fieldMap AssetSealedTokens (elem t) aid
      _ -> error "Unhandled release token cost source"
  FieldResourceCost (FieldCost mtchr fld) -> do
    n <- getSum <$> selectAgg Sum fld mtchr
    fieldP InvestigatorResources (>= n) iid
  SupplyCost locationMatcher supply ->
    iid
      <=~> (Matcher.InvestigatorWithSupply supply
           <> Matcher.InvestigatorAt locationMatcher
           )

getActions :: (Monad m, HasGame m) => InvestigatorId -> Window -> m [Ability]
getActions iid window = getActionsWith iid window id

getActionsWith
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Window
  -> (Ability -> Ability)
  -> m [Ability]
getActionsWith iid window f = do
  modifiersForFilter <- getModifiers (InvestigatorTarget iid)
  let
    abilityFilters = mapMaybe
      (\case
        CannotTriggerAbilityMatching m -> Just m
        _ -> Nothing
      )
      modifiersForFilter
  unfilteredActions <- map f . nub <$> getAllAbilities
  actions' <- if null abilityFilters
    then pure unfilteredActions
    else do
      ignored <- select (mconcat abilityFilters)
      pure $ filter (`member` ignored) unfilteredActions
  actionsWithSources <- concat <$> for
    actions'
    \action -> do
      case abilitySource action of
        ProxySource (AgendaMatcherSource m) base -> do
          sources <- selectListMap AgendaSource m
          pure $ map
            (\source -> action { abilitySource = ProxySource source base })
            sources
        ProxySource (AssetMatcherSource m) base -> do
          sources <- selectListMap AssetSource m
          pure $ map
            (\source -> action { abilitySource = ProxySource source base })
            sources
        ProxySource (LocationMatcherSource m) base -> do
          sources <- selectListMap LocationSource m
          pure $ map
            (\source -> action { abilitySource = ProxySource source base })
            sources
        ProxySource (EnemyMatcherSource m) base -> do
          sources <- selectListMap EnemySource m
          pure $ map
            (\source -> action { abilitySource = ProxySource source base })
            sources
        _ -> pure [action]

  actions'' <- catMaybes <$> for
    actionsWithSources
    \ability -> do
      modifiers' <- getModifiers (sourceToTarget $ abilitySource ability)
      investigatorModifiers <- getModifiers (InvestigatorTarget iid)
      cardClasses <- case abilitySource ability of
        AssetSource aid -> field AssetClasses aid
        _ -> pure $ singleton Neutral
      let
        -- Lola Hayes: Forced abilities will always trigger
        prevents (CanOnlyUseCardsInRole role) =
          null (setFromList [role, Neutral] `intersect` cardClasses)
            && not (isForcedAbility ability)
        prevents CannotTriggerFastAbilities = isFastAbility ability
        prevents _ = False
        -- If the window is fast we only permit fast abilities, but forced
        -- abilities need to be everpresent so we include them
        needsToBeFast = windowType window == Window.FastPlayerWindow && not
          (isFastAbility ability
          || isForcedAbility ability
          || isReactionAbility ability
          )
      if any prevents investigatorModifiers || needsToBeFast
        then pure Nothing
        else pure $ Just $ applyAbilityModifiers ability modifiers'

  actions''' <-
    filterM
      (\action ->
        liftA2
          (&&)
          (getCanPerformAbility iid (abilitySource action) window action)
          (getCanAffordAbility iid action window)
      )
      actions''
  let forcedActions = filter isForcedAbility actions'''
  pure $ if null forcedActions then actions''' else forcedActions

getPlayerCountValue :: (Monad m, HasGame m) => GameValue -> m Int
getPlayerCountValue gameValue = fromGameValue gameValue <$> getPlayerCount

getSpendableClueCount :: (Monad m, HasGame m) => [InvestigatorId] -> m Int
getSpendableClueCount investigatorIds = getSum <$> selectAgg
  Sum
  InvestigatorClues
  (Matcher.InvestigatorWithoutModifier CannotSpendClues
  <> Matcher.AnyInvestigator (map Matcher.InvestigatorWithId investigatorIds)
  )

targetToSource :: Target -> Source
targetToSource = \case
  InvestigatorTarget iid -> InvestigatorSource iid
  InvestigatorHandTarget iid -> InvestigatorSource iid
  InvestigatorDiscardTarget iid -> InvestigatorSource iid
  AssetTarget aid -> AssetSource aid
  EnemyTarget eid -> EnemySource eid
  ScenarioTarget -> ScenarioSource
  EffectTarget eid -> EffectSource eid
  PhaseTarget _ -> error "no need"
  LocationTarget lid -> LocationSource lid
  (SetAsideLocationsTarget _) -> error "can not convert"
  SkillTestTarget -> error "can not convert"
  AfterSkillTestTarget -> AfterSkillTestSource
  TreacheryTarget tid -> TreacherySource tid
  EncounterDeckTarget -> error "can not covert"
  ScenarioDeckTarget -> error "can not covert"
  AgendaTarget aid -> AgendaSource aid
  ActTarget aid -> ActSource aid
  CardIdTarget _ -> error "can not convert"
  CardCodeTarget _ -> error "can not convert"
  SearchedCardTarget _ -> error "can not convert"
  EventTarget eid -> EventSource eid
  SkillTarget sid -> SkillSource sid
  SkillTestInitiatorTarget _ -> error "can not convert"
  TokenTarget tid -> TokenSource tid
  TokenFaceTarget _ -> error "Not convertable"
  TestTarget -> TestSource mempty
  ResourceTarget -> ResourceSource
  ActDeckTarget -> ActDeckSource
  AgendaDeckTarget -> AgendaDeckSource
  InvestigationTarget{} -> error "not converted"
  YouTarget -> YouSource
  ProxyTarget{} -> error "can not convert"
  CardTarget{} -> error "can not convert"
  StoryTarget code -> StorySource code
  AgendaMatcherTarget _ -> error "can not convert"
  CampaignTarget -> CampaignSource
  AbilityTarget _ _ -> error "can not convert"

sourceToTarget :: Source -> Target
sourceToTarget = \case
  YouSource -> YouTarget
  AssetSource aid -> AssetTarget aid
  EnemySource eid -> EnemyTarget eid
  CardIdSource cid -> CardIdTarget cid
  ScenarioSource -> ScenarioTarget
  InvestigatorSource iid -> InvestigatorTarget iid
  CardCodeSource cid -> CardCodeTarget cid
  TokenSource t -> TokenTarget t
  TokenEffectSource _ -> error "not implemented"
  AgendaSource aid -> AgendaTarget aid
  LocationSource lid -> LocationTarget lid
  SkillTestSource{} -> SkillTestTarget
  AfterSkillTestSource -> AfterSkillTestTarget
  TreacherySource tid -> TreacheryTarget tid
  EventSource eid -> EventTarget eid
  SkillSource sid -> SkillTarget sid
  EmptyDeckSource -> error "not implemented"
  DeckSource -> error "not implemented"
  GameSource -> error "not implemented"
  ActSource aid -> ActTarget aid
  PlayerCardSource _ -> error "not implemented"
  EncounterCardSource _ -> error "not implemented"
  TestSource{} -> TestTarget
  ProxySource _ source -> sourceToTarget source
  EffectSource eid -> EffectTarget eid
  ResourceSource -> ResourceTarget
  AbilitySource{} -> error "not implemented"
  ActDeckSource -> ActDeckTarget
  AgendaDeckSource -> AgendaDeckTarget
  AgendaMatcherSource{} -> error "not converted"
  AssetMatcherSource{} -> error "not converted"
  LocationMatcherSource{} -> error "not converted"
  EnemyMatcherSource{} -> error "not converted"
  EnemyAttackSource a -> EnemyTarget a
  StorySource code -> StoryTarget code
  CampaignSource -> CampaignTarget
  ThisCard -> error "not converted"
  CardCostSource _ -> error "not converted"

addCampaignCardToDeckChoice
  :: InvestigatorId -> [InvestigatorId] -> CardDef -> Message
addCampaignCardToDeckChoice leadInvestigatorId investigatorIds cardDef =
  chooseOne
    leadInvestigatorId
    [ Label
      ("Add " <> display name <> " to a deck")
      [ chooseOne
          leadInvestigatorId
          [ TargetLabel
              (InvestigatorTarget iid)
              [AddCampaignCardToDeck iid cardDef]
          | iid <- investigatorIds
          ]
      ]
    , Label ("Do not add " <> display name <> " to any deck") []
    ]
  where name = cdName cardDef

hasFightActions
  :: (Monad m, HasGame m) => InvestigatorId -> Matcher.WindowMatcher -> Source -> [Window] -> m Bool
hasFightActions iid window source windows' = anyM (\a -> anyM (\w -> getCanPerformAbility iid source w a) windows') =<< selectList
  (Matcher.AbilityIsAction Action.Fight <> Matcher.AbilityWindow window)

hasEvadeActions
  :: (Monad m, HasGame m) => InvestigatorId -> Matcher.WindowMatcher -> Source -> [Window] -> m Bool
hasEvadeActions iid window source windows' = anyM (\a -> anyM (\w -> getCanPerformAbility iid source w a) windows') =<< selectList
  (Matcher.AbilityIsAction Action.Evade <> Matcher.AbilityWindow window)

getIsPlayable
  :: (HasCallStack, Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> CostStatus
  -> [Window]
  -> Card
  -> m Bool
getIsPlayable iid source costStatus windows' c = do
  availableResources <- field InvestigatorResources iid
  getIsPlayableWithResources iid source availableResources costStatus windows' c

withDepthGuard :: (Monad m, HasGame m) => Int -> a -> ReaderT Game m a -> m a
withDepthGuard maxDepth defaultValue body = do
  game <- getGame
  flip runReaderT game $ do
    depth <- getDepthLock
    if depth > maxDepth then pure defaultValue else local delve body

getIsPlayableWithResources
  :: (HasCallStack, Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> Int
  -> CostStatus
  -> [Window]
  -> Card
  -> m Bool
getIsPlayableWithResources _ _ _ _ _ (VengeanceCard _) = pure False
getIsPlayableWithResources _ _ _ _ _ (EncounterCard _) = pure False -- TODO: there might be some playable ones?
getIsPlayableWithResources iid source availableResources costStatus windows' c@(PlayerCard _)
  = withDepthGuard 3 False $ do
    iids <- filter (/= iid) <$> getInvestigatorIds
    iidsWithModifiers <- for iids $ \iid' -> do
      modifiers <- getModifiers (InvestigatorTarget iid')
      pure (iid', modifiers)
    canHelpPay <- flip filterM iidsWithModifiers $ \(_, modifiers) -> do
      flip anyM modifiers $ \case
        CanSpendResourcesOnCardFromInvestigator iMatcher cMatcher -> liftA2
          (&&)
          (member iid <$> select iMatcher)
          (pure $ cardMatch c cMatcher)
        _ -> pure False
    additionalResources <-
      sum <$> traverse (field InvestigatorResources . fst) canHelpPay
    modifiers <- getModifiers (InvestigatorTarget iid)
    let title = nameTitle (cdName pcDef)
    passesUnique <- case (cdUnique pcDef, cdCardType pcDef) of
      (True, AssetType) -> not <$> case nameSubtitle (cdName pcDef) of
        Nothing -> selectAny (Matcher.AssetWithTitle title)
        Just subtitle -> selectAny (Matcher.AssetWithFullTitle title subtitle)
      _ -> pure True

    let
      duringTurnWindow = Window Timing.When (Window.DuringTurn iid)
      notFastWindow = any (`elem` windows') [duringTurnWindow]
      canBecomeFast =
        CannotPlay Matcher.FastCard
          `notElem` modifiers
          && foldr applyModifier False modifiers
      canBecomeFastWindow =
        if canBecomeFast then Just (Matcher.DuringTurn Matcher.You) else Nothing
      applyModifier (CanBecomeFast cardMatcher) _ = cardMatch c cardMatcher
      applyModifier _ val = val
    modifiedCardCost <-
      getPotentiallyModifiedCardCost iid c =<< getModifiedCardCost iid c
    passesCriterias <- maybe
      (pure True)
      (passesCriteria iid (replaceThisCard c source) windows')
      (cdCriteria pcDef)
    inFastWindow <- maybe
      (pure False)
      (cardInFastWindows iid source c windows')
      (cdFastWindow pcDef <|> canBecomeFastWindow)
    canEvade <- hasEvadeActions iid (Matcher.DuringTurn Matcher.You) source windows'
    canFight <- hasFightActions iid (Matcher.DuringTurn Matcher.You) source windows'
    passesLimits <- allM passesLimit (cdLimits pcDef)
    cardModifiers <- getModifiers (CardIdTarget $ toCardId c)
    let
      additionalCosts = flip mapMaybe cardModifiers $ \case
        AdditionalCost x -> Just x
        _ -> Nothing
      sealedTokenCost = flip mapMaybe (setToList $ cdKeywords pcDef) $ \case
        Keyword.Seal matcher ->
          if costStatus == PaidCost then Nothing else Just $ SealCost matcher
        _ -> Nothing

    canAffordAdditionalCosts <- allM
      (getCanAffordCost iid (CardIdSource $ toCardId c) Nothing windows')
      ([ ActionCost 1 | not inFastWindow && costStatus /= PaidCost ]
      <> additionalCosts
      <> sealedTokenCost
      )

    passesSlots <- if null (cdSlots pcDef)
      then pure True
      else do
        possibleSlots <- getPotentialSlots c iid
        pure $ null $ cdSlots pcDef \\ possibleSlots


    pure
      $ (cdCardType pcDef /= SkillType)
      && ((costStatus == PaidCost)
         || (modifiedCardCost <= (availableResources + additionalResources))
         )
      && none prevents modifiers
      && ((isNothing (cdFastWindow pcDef) && notFastWindow) || inFastWindow)
      && (Action.Evade
         `notElem` cdActions pcDef
         || canEvade
         || cdOverrideActionPlayableIfCriteriaMet pcDef
         )
      && (Action.Fight
         `notElem` cdActions pcDef
         || canFight
         || cdOverrideActionPlayableIfCriteriaMet pcDef
         )
      && passesCriterias
      && passesLimits
      && passesUnique
      && passesSlots
      && canAffordAdditionalCosts
 where
  pcDef = toCardDef c
  prevents (CanOnlyUseCardsInRole role) =
    null $ intersect (cdClassSymbols pcDef) (setFromList [Neutral, role])
  prevents (CannotPlay matcher) = cardMatch c matcher
  prevents _ = False
  passesLimit (LimitPerInvestigator m) = case toCardType c of
    AssetType -> do
      n <- selectCount
        (Matcher.AssetControlledBy (Matcher.InvestigatorWithId iid)
        <> Matcher.AssetWithTitle (nameTitle $ toName c)
        )
      pure $ m > n
    _ -> error $ "Not handling card type: " <> show (toCardType c)
  passesLimit (LimitPerTrait t m) = case toCardType c of
    AssetType -> do
      n <- selectCount (Matcher.AssetWithTrait t)
      pure $ m > n
    _ -> error $ "Not handling card type: " <> show (toCardType c)

onSameLocation :: (HasGame m, Monad m) => InvestigatorId -> Placement -> m Bool
onSameLocation iid = \case
  AttachedToLocation lid -> fieldMap InvestigatorLocation (== Just lid) iid
  AtLocation lid -> fieldMap InvestigatorLocation (== Just lid) iid
  InPlayArea iid' -> if iid == iid'
    then pure True
    else liftA2
      (==)
      (field InvestigatorLocation iid')
      (field InvestigatorLocation iid)
  InThreatArea iid' -> if iid == iid'
    then pure True
    else liftA2
      (==)
      (field InvestigatorLocation iid')
      (field InvestigatorLocation iid)
  AttachedToEnemy eid ->
    liftA2 (==) (field EnemyLocation eid) (field InvestigatorLocation iid)
  AttachedToAsset aid _ -> do
    placement' <- field AssetPlacement aid
    onSameLocation iid placement'
  AttachedToAct _ -> pure False
  AttachedToAgenda _ -> pure False
  AttachedToInvestigator iid' -> liftA2
    (==)
    (field InvestigatorLocation iid')
    (field InvestigatorLocation iid)
  Unplaced -> pure False
  TheVoid -> pure False
  Pursuit -> pure False

passesCriteria
  :: (HasCallStack, Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> [Window]
  -> Criterion
  -> m Bool
passesCriteria iid source windows' = \case
  Criteria.TokenCountIs tokenMatcher valueMatcher -> do
    n <- selectCount tokenMatcher
    gameValueMatches n valueMatcher
  Criteria.DuringPhase phaseMatcher -> do
    p <- getPhase
    matchPhase p phaseMatcher
  Criteria.ActionCanBeUndone -> getActionCanBeUndone
  Criteria.DoomCountIs valueMatcher -> do
    doomCount <- getDoomCount
    gameValueMatches doomCount valueMatcher
  Criteria.Negate restriction ->
    not <$> passesCriteria iid source windows' restriction
  Criteria.AllUndefeatedInvestigatorsResigned -> andM
    [ selectNone Matcher.UneliminatedInvestigator
    , selectAny Matcher.ResignedInvestigator -- at least one investigator should have resigned
    ]
  Criteria.EachUndefeatedInvestigator investigatorMatcher -> do
    liftA2
      (==)
      (select Matcher.UneliminatedInvestigator)
      (select investigatorMatcher)
  Criteria.Never -> pure False
  Criteria.InYourHand -> do
    hand <- fieldMap InvestigatorHand (map toCardId) iid
    case source of
      EventSource eid -> pure $ unEventId eid `elem` hand
      TreacherySource tid -> do
        member tid <$> select
          (Matcher.TreacheryInHandOf $ Matcher.InvestigatorWithId iid)
      _ -> error $ "source not handled for in your hand: " <> show source
  Criteria.InThreatAreaOf who -> do
    case source of
      TreacherySource tid ->
        member tid <$> select (Matcher.TreacheryInThreatAreaOf who)
      _ ->
        error
          $ "Can not check if "
          <> show source
          <> " is in players threat area"
  Criteria.Self -> case source of
    InvestigatorSource iid' -> pure $ iid == iid'
    _ -> pure False
  Criteria.ValueIs val valueMatcher -> gameValueMatches val valueMatcher
  Criteria.UnderneathCardCount valueMatcher zone cardMatcher -> do
    let
      getCards = \case
        Criteria.UnderAgendaDeck -> scenarioField ScenarioCardsUnderAgendaDeck
        Criteria.UnderActDeck -> scenarioField ScenarioCardsUnderActDeck
        Criteria.UnderZones zs -> concatMapM getCards zs
    cardCount <- length . filter (`cardMatch` cardMatcher) <$> getCards zone
    gameValueMatches cardCount valueMatcher
  Criteria.SelfHasModifier modifier -> case source of
    InvestigatorSource iid' ->
      elem modifier <$> getModifiers (InvestigatorTarget iid')
    EnemySource iid' -> elem modifier <$> getModifiers (EnemyTarget iid')
    _ -> pure False
  Criteria.Here -> case source of
    LocationSource lid -> fieldP InvestigatorLocation (== Just lid) iid
    ProxySource (LocationSource lid) _ ->
      fieldP InvestigatorLocation (== Just lid) iid
    _ -> pure False
  Criteria.HasSupply s -> fieldP InvestigatorSupplies (elem s) iid
  Criteria.ControlsThis -> case source of
    AssetSource aid -> member aid
      <$> select (Matcher.AssetControlledBy $ Matcher.InvestigatorWithId iid)
    EventSource eid -> member eid
      <$> select (Matcher.EventControlledBy $ Matcher.InvestigatorWithId iid)
    _ -> pure False
  Criteria.DuringSkillTest skillTestMatcher -> do
    mSkillTest <- getSkillTest
    case mSkillTest of
      Nothing -> pure False
      Just skillTest -> skillTestMatches iid source skillTest skillTestMatcher
  Criteria.ChargesOnThis valueMatcher -> case source of
    TreacherySource tid ->
      (`gameValueMatches` valueMatcher) =<< field TreacheryResources tid
    _ -> error "missing ChargesOnThis check"
  Criteria.ResourcesOnThis valueMatcher -> case source of
    TreacherySource tid ->
      (`gameValueMatches` valueMatcher) =<< field TreacheryResources tid
    _ -> error "missing ChargesOnThis check"
  Criteria.ResourcesOnLocation locationMatcher valueMatcher -> do
    total <- getSum <$> selectAgg Sum LocationResources locationMatcher
    gameValueMatches total valueMatcher
  Criteria.CluesOnThis valueMatcher -> case source of
    LocationSource lid ->
      (`gameValueMatches` valueMatcher) =<< field LocationClues lid
    ActSource aid -> (`gameValueMatches` valueMatcher) =<< field ActClues aid
    AssetSource aid ->
      (`gameValueMatches` valueMatcher) =<< field AssetClues aid
    TreacherySource tid ->
      (`gameValueMatches` valueMatcher) =<< field TreacheryClues tid
    _ -> error "missing CluesOnThis check"
  Criteria.HorrorOnThis valueMatcher -> case source of
    AssetSource aid ->
      (`gameValueMatches` valueMatcher) =<< field AssetHorror aid
    _ -> error $ "missing HorrorOnThis check for " <> show source
  Criteria.DamageOnThis valueMatcher -> case source of
    AssetSource aid ->
      (`gameValueMatches` valueMatcher) =<< field AssetDamage aid
    _ -> error $ "missing DamageOnThis check for " <> show source
  Criteria.ScenarioDeckWithCard key -> notNull <$> getScenarioDeck key
  Criteria.Uncontrolled -> case source of
    AssetSource aid -> fieldP AssetController isNothing aid
    ProxySource (AssetSource aid) _ -> fieldP AssetController isNothing aid
    _ -> error $ "missing ControlsThis check for source: " <> show source
  Criteria.OnSameLocation -> case source of
    AssetSource aid -> do
      placement <- field AssetPlacement aid
      onSameLocation iid placement
    EnemySource eid -> liftA2
      (==)
      (selectOne $ Matcher.LocationWithEnemy $ Matcher.EnemyWithId eid)
      (field InvestigatorLocation iid)
    TreacherySource tid -> field TreacheryAttachedTarget tid >>= \case
      Just (LocationTarget lid) ->
        fieldP InvestigatorLocation (== Just lid) iid
      Just (InvestigatorTarget iid') -> if iid == iid'
        then pure True
        else do
          l1 <- field InvestigatorLocation iid
          l2 <- field InvestigatorLocation iid'
          pure $ isJust l1 && l1 == l2
      Just _ -> pure False
      Nothing -> pure False
    ProxySource (AssetSource aid) _ ->
      liftA2 (==) (field AssetLocation aid) (field InvestigatorLocation iid)
    _ -> error $ "missing OnSameLocation check for source: " <> show source
  Criteria.DuringTurn who -> selectAny (Matcher.TurnInvestigator <> who)
  Criteria.CardExists cardMatcher -> selectAny cardMatcher
  Criteria.ExtendedCardExists cardMatcher -> selectAny cardMatcher
  Criteria.PlayableCardExistsWithCostReduction n cardMatcher -> do
    mTurnInvestigator <- selectOne Matcher.TurnInvestigator
    let
      updatedWindows = case mTurnInvestigator of
        Nothing -> windows'
        Just tIid ->
          nub $ Window Timing.When (Window.DuringTurn tIid) : windows'
    availableResources <- field InvestigatorResources iid
    results <- selectList cardMatcher
    anyM
      (getIsPlayableWithResources
        iid
        source
        (availableResources + n)
        UnpaidCost
        updatedWindows
      )
      results
  Criteria.PlayableCardExists cardMatcher -> do
    mTurnInvestigator <- selectOne Matcher.TurnInvestigator
    let
      updatedWindows = case mTurnInvestigator of
        Nothing -> windows'
        Just tIid ->
          nub $ Window Timing.When (Window.DuringTurn tIid) : windows'
    results <- selectList cardMatcher
    anyM (getIsPlayable iid source UnpaidCost updatedWindows) results
  Criteria.PlayableCardInDiscard discardSignifier cardMatcher -> do
    let
      investigatorMatcher = case discardSignifier of
        Criteria.DiscardOf matcher -> matcher
        Criteria.AnyPlayerDiscard -> Matcher.Anyone
      windows'' =
        [ Window Timing.When (Window.DuringTurn iid)
        , Window Timing.When Window.FastPlayerWindow
        ]
    investigatorIds <-
      filterM
          (fmap (notElem CardsCannotLeaveYourDiscardPile)
          . getModifiers
          . InvestigatorTarget
          )
        =<< selectList investigatorMatcher
    discards <-
      filter (`cardMatch` cardMatcher)
        <$> concatMapM (field InvestigatorDiscard) investigatorIds
    anyM (getIsPlayable iid source UnpaidCost windows'' . PlayerCard) discards
  Criteria.FirstAction -> fieldP InvestigatorActionsTaken null iid
  Criteria.NoRestriction -> pure True
  Criteria.OnLocation locationMatcher -> do
    mlid <- field InvestigatorLocation iid
    case mlid of
      Nothing -> pure False
      Just lid -> anyM
        (\window -> locationMatches iid source window lid locationMatcher)
        windows'
  Criteria.ReturnableCardInDiscard discardSignifier traits -> do
    let
      investigatorMatcher = case discardSignifier of
        Criteria.DiscardOf matcher -> matcher
        Criteria.AnyPlayerDiscard -> Matcher.Anyone
    investigatorIds <-
      filterM
          (fmap (notElem CardsCannotLeaveYourDiscardPile)
          . getModifiers
          . InvestigatorTarget
          )
        =<< selectList investigatorMatcher
    discards <- concatMapM (field InvestigatorDiscard) investigatorIds
    let
      filteredDiscards = case traits of
        [] -> discards
        traitsToMatch ->
          filter (any (`elem` traitsToMatch) . toTraits) discards
    pure $ notNull filteredDiscards
  Criteria.CardInDiscard discardSignifier cardMatcher -> do
    let
      investigatorMatcher = case discardSignifier of
        Criteria.DiscardOf matcher -> matcher
        Criteria.AnyPlayerDiscard -> Matcher.Anyone
    investigatorIds <- selectList investigatorMatcher
    discards <- concatMapM (field InvestigatorDiscard) investigatorIds
    let filteredDiscards = filter (`cardMatch` cardMatcher) discards
    pure $ notNull filteredDiscards
  Criteria.ClueOnLocation ->
    maybe (pure False) (fieldP LocationClues (> 0))
      =<< field InvestigatorLocation iid
  Criteria.EnemyCriteria enemyCriteria ->
    passesEnemyCriteria iid source windows' enemyCriteria
  Criteria.SetAsideCardExists matcher -> selectAny matcher
  Criteria.SetAsideEnemyExists matcher ->
    selectAny $ Matcher.SetAsideMatcher matcher
  Criteria.OnAct step -> do
    actId <- selectJust Matcher.AnyAct
    (== AS.ActStep step) . AS.actStep <$> field ActSequence actId
  Criteria.AgendaExists matcher -> selectAny matcher
  Criteria.AssetExists matcher -> do
    mlid <- field InvestigatorLocation iid
    selectAny (Matcher.resolveAssetMatcher iid mlid matcher)
  Criteria.TreacheryExists matcher -> selectAny matcher
  Criteria.InvestigatorExists matcher ->
    -- Because the matcher can't tell who is asking, we need to replace
    -- The You matcher by the Id of the investigator asking
    selectAny (Matcher.replaceYouMatcher iid matcher)
  Criteria.InvestigatorsHaveSpendableClues valueMatcher -> do
    total <- getSum <$> selectAgg
      Sum
      InvestigatorClues
      (Matcher.InvestigatorWithoutModifier CannotSpendClues)
    total `gameValueMatches` valueMatcher
  Criteria.Criteria rs -> allM (passesCriteria iid source windows') rs
  Criteria.AnyCriterion rs -> anyM (passesCriteria iid source windows') rs
  Criteria.LocationExists matcher -> do
    mlid <- field InvestigatorLocation iid
    selectAny (Matcher.replaceYourLocation iid mlid matcher)
  Criteria.LocationCount n matcher -> do
    mlid <- field InvestigatorLocation iid
    (== n) <$> selectCount (Matcher.replaceYourLocation iid mlid matcher)
  Criteria.AllLocationsMatch targetMatcher locationMatcher -> do
    mlid <- field InvestigatorLocation iid
    targets <- select (Matcher.replaceYourLocation iid mlid targetMatcher)
    actual <- select (Matcher.replaceYourLocation iid mlid locationMatcher)
    pure $ all (`member` actual) targets
  Criteria.InvestigatorIsAlone ->
    (== 1) <$> selectCount (Matcher.colocatedWith iid)
  Criteria.InVictoryDisplay cardMatcher valueMatcher -> do
    vCards <- filter (`cardMatch` cardMatcher)
      <$> scenarioField ScenarioVictoryDisplay
    gameValueMatches (length vCards) valueMatcher
  Criteria.OwnCardWithDoom -> do
    anyAssetsHaveDoom <- selectAny
      (Matcher.AssetControlledBy Matcher.You <> Matcher.AssetWithAnyDoom)
    investigatorHasDoom <- fieldP InvestigatorDoom (> 0) iid
    pure $ investigatorHasDoom || anyAssetsHaveDoom
  Criteria.ScenarioCardHasResignAbility -> do
    actions' <- getAllAbilities
    pure $ flip
      any
      actions'
      \ability -> case abilityType ability of
        ActionAbility (Just Action.Resign) _ -> True
        _ -> False
  Criteria.Remembered logKey -> do
    elem logKey <$> scenarioFieldMap ScenarioRemembered HashSet.toList
  Criteria.RememberedAtLeast value logKeys -> do
    n <-
      length
      . filter (`elem` logKeys)
      <$> scenarioFieldMap ScenarioRemembered HashSet.toList
    gameValueMatches n (Matcher.AtLeast value)
  Criteria.AtLeastNCriteriaMet n criteria -> do
    m <- countM (passesCriteria iid source windows') criteria
    pure $ m >= n

-- | Build a matcher and check the list
passesEnemyCriteria
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> [Window]
  -> Criteria.EnemyCriterion
  -> m Bool
passesEnemyCriteria _iid source windows' criterion = selectAny
  =<< matcher criterion
 where
  matcher = \case
    Criteria.EnemyMatchesCriteria ms -> mconcatMapM matcher ms
    Criteria.EnemyExists m -> pure m
    Criteria.EnemyExistsAtAttachedLocation m -> case source of
      EventSource e -> do
        field EventAttachedTarget e >>= \case
          Just (LocationTarget lid) ->
            pure $ m <> Matcher.EnemyAt (Matcher.LocationWithId lid)
          Just _ -> error "Event must be attached to a location"
          Nothing -> error "Event must be attached to a location"
      _ -> error $ "Does not handle source: " <> show source
    Criteria.ThisEnemy enemyMatcher -> case source of
      EnemySource eid -> pure $ Matcher.EnemyWithId eid <> enemyMatcher
      _ -> error "Invalid source for ThisEnemy"
    Criteria.NotAttackingEnemy ->
      -- TODO: should not be multiple enemies, but if so need to OR not AND matcher
      let
        getAttackingEnemy = \case
          Window _ (Window.EnemyAttacks _ eid _) -> Just eid
          _ -> Nothing
      in
        case mapMaybe getAttackingEnemy windows' of
          [] -> error "can not be called without enemy source"
          xs -> pure $ Matcher.NotEnemy (concatMap Matcher.EnemyWithId xs)

getModifiedCardCost :: (Monad m, HasGame m) => InvestigatorId -> Card -> m Int
getModifiedCardCost iid c@(PlayerCard _) = do
  modifiers <- getModifiers (InvestigatorTarget iid)
  cardModifiers <- getModifiers (CardIdTarget $ toCardId c)
  foldM applyModifier startingCost (modifiers <> cardModifiers)
 where
  pcDef = toCardDef c
  startingCost = case cdCost pcDef of
    Just (StaticCost n) -> n
    Just DynamicCost -> 0
    Nothing -> 0
  -- A card like The Painted World which has no cost, but can be "played", should not have it's cost modified
  applyModifier n _ | isNothing (cdCost pcDef) = pure n
  applyModifier n (ReduceCostOf cardMatcher m) = do
    pure $ if c `cardMatch` cardMatcher then max 0 (n - m) else n
  applyModifier n (IncreaseCostOf cardMatcher m) = do
    pure $ if c `cardMatch` cardMatcher then n + m else n
  applyModifier n _ = pure n
getModifiedCardCost iid c@(EncounterCard _) = do
  modifiers <- getModifiers (InvestigatorTarget iid)
  foldM
    applyModifier
    (error "we need so specify ecCost for this to work")
    modifiers
 where
  applyModifier n (ReduceCostOf cardMatcher m) = do
    pure $ if c `cardMatch` cardMatcher then max 0 (n - m) else n
  applyModifier n (IncreaseCostOf cardMatcher m) = do
    pure $ if c `cardMatch` cardMatcher then n + m else n
  applyModifier n _ = pure n
getModifiedCardCost _ (VengeanceCard _) = error "should not happen for vengeance"

getPotentiallyModifiedCardCost
  :: (Monad m, HasGame m) => InvestigatorId -> Card -> Int -> m Int
getPotentiallyModifiedCardCost iid c@(PlayerCard _) startingCost = do
  modifiers <- getModifiers (InvestigatorTarget iid)
  cardModifiers <- getModifiers (CardIdTarget $ toCardId c)
  foldM applyModifier startingCost (modifiers <> cardModifiers)
 where
  applyModifier n (CanReduceCostOf cardMatcher m) = do
    pure $ if c `cardMatch` cardMatcher then max 0 (n - m) else n
  applyModifier n _ = pure n
getPotentiallyModifiedCardCost iid c@(EncounterCard _) _ = do
  modifiers <- getModifiers (InvestigatorTarget iid)
  foldM
    applyModifier
    (error "we need so specify ecCost for this to work")
    modifiers
 where
  applyModifier n (CanReduceCostOf cardMatcher m) = do
    pure $ if c `cardMatch` cardMatcher then max 0 (n - m) else n
  applyModifier n _ = pure n
getPotentiallyModifiedCardCost _ (VengeanceCard _) _ = error "should not check vengeance card"

cardInFastWindows
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> Card
  -> [Window]
  -> Matcher.WindowMatcher
  -> m Bool
cardInFastWindows iid source _ windows' matcher =
  anyM (\window -> windowMatches iid source window matcher) windows'

windowMatches
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> Window
  -> Matcher.WindowMatcher
  -> m Bool
windowMatches _ _ (Window _ Window.DoNotCheckWindow) = pure . const True
windowMatches iid source window' = \case
  Matcher.AnyWindow -> pure True
  Matcher.AddingToCurrentDepth -> case window' of
    Window _ Window.AddingToCurrentDepth -> pure True
    _ -> pure False
  Matcher.DrawingStartingHand timing whoMatcher -> case window' of
    Window t (Window.DrawingStartingHand who) | t == timing ->
      matchWho iid who whoMatcher
    _ -> pure False
  Matcher.MovedFromHunter timing enemyMatcher -> case window' of
    Window t (Window.MovedFromHunter eid) | t == timing ->
      member eid <$> select enemyMatcher
    _ -> pure False
  Matcher.PlaceUnderneath timing targetMatcher cardMatcher -> case window' of
    Window t (Window.PlaceUnderneath target' card) | t == timing -> liftA2
      (&&)
      (targetMatches target' targetMatcher)
      (pure $ cardMatch card cardMatcher)
    _ -> pure False
  Matcher.ActivateAbility timing whoMatcher abilityMatcher -> case window' of
    Window t (Window.ActivateAbility who ability) | t == timing -> liftA2
      (&&)
      (matchWho iid who whoMatcher)
      (member ability <$> select abilityMatcher)
    _ -> pure False
  Matcher.CommittedCard timing whoMatcher cardMatcher -> case window' of
    Window t (Window.CommittedCard who card) | t == timing -> liftA2
      (&&)
      (matchWho iid who whoMatcher)
      (pure $ cardMatch card cardMatcher)
    _ -> pure False
  Matcher.CommittedCards timing whoMatcher cardListMatcher -> case window' of
    Window t (Window.CommittedCards who cards) | t == timing -> liftA2
      (&&)
      (matchWho iid who whoMatcher)
      (cardListMatches cards cardListMatcher)
    _ -> pure False
  Matcher.EnemyAttemptsToSpawnAt timing enemyMatcher locationMatcher ->
    case window' of
      Window t (Window.EnemyAttemptsToSpawnAt eid locationMatcher')
        | t == timing -> do
          case locationMatcher of
            Matcher.LocationNotInPlay -> do
              liftA2
                (&&)
                (enemyMatches eid enemyMatcher)
                (selectNone locationMatcher')
            _ -> pure False -- TODO: We may need more things here
      _ -> pure False
  Matcher.TookControlOfAsset timing whoMatcher assetMatcher -> case window' of
    Window t (Window.TookControlOfAsset who aid) | t == timing -> liftA2
      (&&)
      (matchWho iid who whoMatcher)
      (member aid <$> select assetMatcher)
    _ -> pure False
  Matcher.AssetHealed timing damageType assetMatcher sourceMatcher ->
    case window' of
      Window t (Window.Healed damageType' (AssetTarget assetId) source' _) | t == timing && damageType == damageType' ->
        andM [member assetId <$> select assetMatcher, sourceMatches source' sourceMatcher]
      _ -> pure False
  Matcher.InvestigatorHealed timing damageType whoMatcher sourceMatcher ->
    case window' of
      Window t (Window.Healed damageType' (InvestigatorTarget who) source' _) | t == timing && damageType == damageType' ->
        andM [matchWho iid who whoMatcher, sourceMatches source' sourceMatcher]
      _ -> pure False
  Matcher.WouldPerformRevelationSkillTest timing whoMatcher ->
    case window' of
      Window t (Window.WouldPerformRevelationSkillTest who) | t == timing ->
        matchWho iid who whoMatcher
      _ -> pure False
  Matcher.WouldDrawEncounterCard timing whoMatcher phaseMatcher ->
    case window' of
      Window t (Window.WouldDrawEncounterCard who p) | t == timing ->
        liftA2 (&&) (matchWho iid who whoMatcher) (matchPhase p phaseMatcher)
      _ -> pure False
  Matcher.AmongSearchedCards whoMatcher -> case window' of
    Window _ (Window.AmongSearchedCards who) -> matchWho iid who whoMatcher
    _ -> pure False
  Matcher.Discarded timing whoMatcher cardMatcher -> case window' of
    Window t (Window.Discarded who card) | t == timing ->
      (cardMatch card cardMatcher &&) <$> matchWho iid who whoMatcher
    _ -> pure False
  Matcher.AssetWouldBeDiscarded timing assetMatcher -> case window' of
    Window t (Window.WouldBeDiscarded (AssetTarget aid)) | t == timing ->
      elem aid <$> select assetMatcher
    _ -> pure False
  Matcher.EnemyWouldBeDiscarded timing enemyMatcher -> case window' of
    Window t (Window.WouldBeDiscarded (EnemyTarget eid)) | t == timing ->
      elem eid <$> select enemyMatcher
    _ -> pure False
  Matcher.AgendaAdvances timingMatcher agendaMatcher -> case window' of
    Window t (Window.AgendaAdvance aid) | t == timingMatcher ->
      agendaMatches aid agendaMatcher
    _ -> pure False
  Matcher.MovedBy timingMatcher whoMatcher sourceMatcher -> case window' of
    Window t (Window.MovedBy source' _ who) | t == timingMatcher -> liftA2
      (&&)
      (matchWho iid who whoMatcher)
      (sourceMatches source' sourceMatcher)
    _ -> pure False
  Matcher.MovedButBeforeEnemyEngagement timingMatcher whoMatcher whereMatcher
    -> case window' of
      Window t (Window.MovedButBeforeEnemyEngagement who locationId)
        | t == timingMatcher -> liftA2
          (&&)
          (matchWho iid who whoMatcher)
          (locationMatches iid source window' locationId whereMatcher)
      _ -> pure False
  Matcher.InvestigatorDefeated timingMatcher sourceMatcher defeatedByMatcher whoMatcher
    -> case window' of
      Window t (Window.InvestigatorDefeated source' defeatedBy who)
        | t == timingMatcher -> andM
          [ matchWho iid who whoMatcher
          , sourceMatches source' sourceMatcher
          , defeatedByMatches defeatedBy defeatedByMatcher
          ]
      _ -> pure False
  Matcher.InvestigatorWouldBeDefeated timingMatcher sourceMatcher defeatedByMatcher whoMatcher
    -> case window' of
      Window t (Window.InvestigatorWouldBeDefeated source' defeatedBy who)
        | t == timingMatcher -> andM
          [ matchWho iid who whoMatcher
          , sourceMatches source' sourceMatcher
          , defeatedByMatches defeatedBy defeatedByMatcher
          ]
      _ -> pure False
  Matcher.AgendaWouldAdvance timingMatcher advancementReason agendaMatcher ->
    case window' of
      Window t (Window.AgendaWouldAdvance advancementReason' aid)
        | t == timingMatcher && advancementReason == advancementReason' -> agendaMatches
          aid
          agendaMatcher
      _ -> pure False
  Matcher.PlacedCounter whenMatcher whoMatcher counterMatcher valueMatcher ->
    case window' of
      Window t (Window.PlacedHorror (InvestigatorTarget iid') n)
        | t == whenMatcher && counterMatcher == Matcher.HorrorCounter -> liftA2
          (&&)
          (matchWho iid iid' whoMatcher)
          (gameValueMatches n valueMatcher)
      Window t (Window.PlacedDamage (InvestigatorTarget iid') n)
        | t == whenMatcher && counterMatcher == Matcher.DamageCounter -> liftA2
          (&&)
          (matchWho iid iid' whoMatcher)
          (gameValueMatches n valueMatcher)
      _ -> pure False
  Matcher.PlacedCounterOnLocation whenMatcher whereMatcher counterMatcher valueMatcher
    -> case window' of
      Window t (Window.PlacedClues (LocationTarget locationId) n)
        | t == whenMatcher && counterMatcher == Matcher.ClueCounter -> liftA2
          (&&)
          (locationMatches iid source window' locationId whereMatcher)
          (gameValueMatches n valueMatcher)
      Window t (Window.PlacedResources (LocationTarget locationId) n)
        | t == whenMatcher && counterMatcher == Matcher.ResourceCounter -> liftA2
          (&&)
          (locationMatches iid source window' locationId whereMatcher)
          (gameValueMatches n valueMatcher)
      _ -> pure False
  Matcher.PlacedCounterOnEnemy whenMatcher enemyMatcher counterMatcher valueMatcher
    -> case window' of
      Window t (Window.PlacedClues (EnemyTarget enemyId) n)
        | t == whenMatcher && counterMatcher == Matcher.ClueCounter -> liftA2
          (&&)
          (enemyMatches enemyId enemyMatcher)
          (gameValueMatches n valueMatcher)
      Window t (Window.PlacedDoom (EnemyTarget enemyId) n)
        | t == whenMatcher && counterMatcher == Matcher.DoomCounter -> liftA2
          (&&)
          (enemyMatches enemyId enemyMatcher)
          (gameValueMatches n valueMatcher)
      _ -> pure False
  Matcher.PlacedCounterOnAgenda whenMatcher agendaMatcher counterMatcher valueMatcher
    -> case window' of
      Window t (Window.PlacedDoom (AgendaTarget agendaId) n)
        | t == whenMatcher && counterMatcher == Matcher.DoomCounter -> liftA2
          (&&)
          (agendaMatches agendaId agendaMatcher)
          (gameValueMatches n valueMatcher)
      _ -> pure False
  Matcher.RevealLocation timingMatcher whoMatcher locationMatcher ->
    case window' of
      Window t (Window.RevealLocation who locationId) | t == timingMatcher ->
        liftA2
          (&&)
          (matchWho iid who whoMatcher)
          (locationMatches iid source window' locationId locationMatcher)
      _ -> pure False
  Matcher.FlipLocation timingMatcher whoMatcher locationMatcher ->
    case window' of
      Window t (Window.FlipLocation who locationId) | t == timingMatcher ->
        liftA2
          (&&)
          (matchWho iid who whoMatcher)
          (locationMatches iid source window' locationId locationMatcher)
      _ -> pure False
  Matcher.GameEnds timingMatcher -> case window' of
    Window t Window.EndOfGame -> pure $ t == timingMatcher
    _ -> pure False
  Matcher.InvestigatorEliminated timingMatcher whoMatcher -> case window' of
    Window t (Window.InvestigatorEliminated who) | t == timingMatcher ->
      matchWho iid who (Matcher.IncludeEliminated $ whoMatcher)
    _ -> pure False
  Matcher.PutLocationIntoPlay timingMatcher whoMatcher locationMatcher ->
    case window' of
      Window t (Window.PutLocationIntoPlay who locationId)
        | t == timingMatcher -> liftA2
          (&&)
          (matchWho iid who whoMatcher)
          (locationMatches iid source window' locationId locationMatcher)
      _ -> pure False
  Matcher.PlayerHasPlayableCard cardMatcher -> do
    -- TODO: do we need to grab the card source?
    -- cards <- filter (/= c) <$> getList cardMatcher
    cards <- selectList cardMatcher
    anyM (getIsPlayable iid source UnpaidCost [window']) cards
  Matcher.PhaseBegins whenMatcher phaseMatcher -> case window' of
    Window t Window.AnyPhaseBegins | whenMatcher == t ->
      pure $ phaseMatcher == Matcher.AnyPhase
    Window t (Window.PhaseBegins p) | whenMatcher == t ->
      matchPhase p phaseMatcher
    _ -> pure False
  Matcher.PhaseEnds whenMatcher phaseMatcher -> case window' of
    Window t (Window.PhaseEnds p) | whenMatcher == t ->
      matchPhase p phaseMatcher
    _ -> pure False
  Matcher.PhaseStep whenMatcher phaseStepMatcher -> case window' of
    Window t Window.EnemiesAttackStep | whenMatcher == t ->
      pure $ phaseStepMatcher == Matcher.EnemiesAttackStep
    _ -> pure False
  Matcher.TurnBegins whenMatcher whoMatcher -> case window' of
    Window t (Window.TurnBegins who) | t == whenMatcher ->
      matchWho iid who whoMatcher
    _ -> pure False
  Matcher.TurnEnds whenMatcher whoMatcher -> case window' of
    Window t (Window.TurnEnds who) | t == whenMatcher ->
      matchWho iid who whoMatcher
    _ -> pure False
  Matcher.RoundEnds whenMatcher -> case window' of
    Window t Window.AtEndOfRound -> pure $ t == whenMatcher
    _ -> pure False
  Matcher.Enters whenMatcher whoMatcher whereMatcher -> case window' of
    Window t (Window.Entering iid' lid) | whenMatcher == t -> liftA2
      (&&)
      (matchWho iid iid' whoMatcher)
      (locationMatches iid source window' lid whereMatcher)
    _ -> pure False
  Matcher.Leaves whenMatcher whoMatcher whereMatcher -> case window' of
    Window t (Window.Leaving iid' lid) | whenMatcher == t -> liftA2
      (&&)
      (matchWho iid iid' whoMatcher)
      (locationMatches iid source window' lid whereMatcher)
    _ -> pure False
  Matcher.Moves whenMatcher whoMatcher sourceMatcher fromMatcher toMatcher -> case window' of
    Window t (Window.Moves iid' source' mFromLid toLid) | whenMatcher == t -> andM
      [ matchWho iid iid' whoMatcher
      , sourceMatches source' sourceMatcher
      , case (fromMatcher, mFromLid) of
        (Matcher.Anywhere, _) -> pure True
        (_, Just fromLid) ->
          locationMatches iid source window' fromLid fromMatcher
        _ -> pure False
      , locationMatches iid source window' toLid toMatcher
      ]
    _ -> pure False
  Matcher.MoveAction whenMatcher whoMatcher fromMatcher toMatcher ->
    case window' of
      Window t (Window.MoveAction iid' fromLid toLid) | whenMatcher == t -> andM
        [ matchWho iid iid' whoMatcher
        , locationMatches iid source window' fromLid fromMatcher
        , locationMatches iid source window' toLid toMatcher
        ]
      _ -> pure False
  Matcher.PerformAction whenMatcher whoMatcher actionMatcher -> case window' of
    Window t (Window.PerformAction iid' action) | whenMatcher == t ->
      andM [matchWho iid iid' whoMatcher, actionMatches action actionMatcher]
    _ -> pure False
  Matcher.WouldHaveSkillTestResult whenMatcher whoMatcher _ skillTestResultMatcher
    -> do
      let
        isWindowMatch = \case
          Matcher.ResultOneOf xs -> anyM isWindowMatch xs
          Matcher.FailureResult _ -> case window' of
            Window t (Window.WouldFailSkillTest who) | t == whenMatcher ->
              matchWho iid who whoMatcher
            _ -> pure False
          Matcher.SuccessResult _ -> case window' of
            Window t (Window.WouldPassSkillTest who) | t == whenMatcher ->
              matchWho iid who whoMatcher
            _ -> pure False
          Matcher.AnyResult -> case window' of
            Window Timing.When (Window.WouldFailSkillTest who) ->
              matchWho iid who whoMatcher
            Window Timing.When (Window.WouldPassSkillTest who) ->
              matchWho iid who whoMatcher
            _ -> pure False
      isWindowMatch skillTestResultMatcher
  Matcher.InitiatedSkillTest whenMatcher whoMatcher skillTypeMatcher skillValueMatcher
    -> case window' of
      Window t (Window.InitiatedSkillTest who maction skillType difficulty)
        | t == whenMatcher -> andM
          [ matchWho iid who whoMatcher
          , skillTestValueMatches
            iid
            difficulty
            maction
            skillType
            skillValueMatcher
          , pure $ skillTypeMatches skillType skillTypeMatcher
          ]
      _ -> pure False
  Matcher.SkillTestEnded whenMatcher whoMatcher skillTestMatcher ->
    case window' of
      Window t (Window.SkillTestEnded skillTest) | whenMatcher == t -> liftA2
        (&&)
        (matchWho iid (skillTestInvestigator skillTest) whoMatcher)
        (skillTestMatches iid source skillTest skillTestMatcher)
      _ -> pure False
  Matcher.SkillTestResult whenMatcher whoMatcher skillMatcher skillTestResultMatcher
    -> do
      mskillTest <- getSkillTest
      matchSkillTest <- case mskillTest of
        Nothing -> pure False
        Just st -> skillTestMatches iid source st skillMatcher
      if not matchSkillTest
        then pure False
        else do
          let
            isWindowMatch = \case
              Matcher.ResultOneOf xs -> anyM isWindowMatch xs
              Matcher.FailureResult gameValueMatcher -> case window' of
                Window t (Window.FailInvestigationSkillTest who lid n)
                  | whenMatcher == t -> case skillMatcher of
                    Matcher.WhileInvestigating whereMatcher -> andM
                      [ matchWho iid who whoMatcher
                      , gameValueMatches n gameValueMatcher
                      , locationMatches iid source window' lid whereMatcher
                      ]
                    _ -> pure False
                Window t (Window.FailAttackEnemy who enemyId n)
                  | whenMatcher == t -> case skillMatcher of
                    Matcher.WhileAttackingAnEnemy enemyMatcher -> andM
                      [ matchWho iid who whoMatcher
                      , gameValueMatches n gameValueMatcher
                      , enemyMatches enemyId enemyMatcher
                      ]
                    _ -> pure False
                Window t (Window.FailEvadeEnemy who enemyId n)
                  | whenMatcher == t -> case skillMatcher of
                    Matcher.WhileEvadingAnEnemy enemyMatcher -> andM
                      [ matchWho iid who whoMatcher
                      , gameValueMatches n gameValueMatcher
                      , enemyMatches enemyId enemyMatcher
                      ]
                    _ -> pure False
                Window t (Window.FailSkillTest who n) | whenMatcher == t ->
                  andM
                    [ matchWho iid who whoMatcher
                    , gameValueMatches n gameValueMatcher
                    ]
                _ -> pure False
              Matcher.SuccessResult gameValueMatcher -> case window' of
                Window t (Window.PassInvestigationSkillTest who lid n)
                  | whenMatcher == t -> case skillMatcher of
                    Matcher.WhileInvestigating whereMatcher -> andM
                      [ matchWho iid who whoMatcher
                      , gameValueMatches n gameValueMatcher
                      , locationMatches iid source window' lid whereMatcher
                      ]
                    _ -> pure False
                Window t (Window.SuccessfulAttackEnemy who enemyId n)
                  | whenMatcher == t -> case skillMatcher of
                    Matcher.WhileAttackingAnEnemy enemyMatcher -> andM
                      [ matchWho iid who whoMatcher
                      , gameValueMatches n gameValueMatcher
                      , enemyMatches enemyId enemyMatcher
                      ]
                    _ -> pure False
                Window t (Window.SuccessfulEvadeEnemy who enemyId n)
                  | whenMatcher == t -> case skillMatcher of
                    Matcher.WhileEvadingAnEnemy enemyMatcher -> andM
                      [ matchWho iid who whoMatcher
                      , gameValueMatches n gameValueMatcher
                      , enemyMatches enemyId enemyMatcher
                      ]
                    _ -> pure False
                Window t (Window.PassSkillTest _ _ who n) | whenMatcher == t ->
                  liftA2
                    (&&)
                    (matchWho iid who whoMatcher)
                    (gameValueMatches n gameValueMatcher)
                _ -> pure False
              Matcher.AnyResult -> case window' of
                Window t (Window.FailSkillTest who _) | whenMatcher == t ->
                  matchWho iid who whoMatcher
                Window t (Window.PassSkillTest _ _ who _) | whenMatcher == t ->
                  matchWho iid who whoMatcher
                _ -> pure False
          isWindowMatch skillTestResultMatcher
  Matcher.DuringTurn whoMatcher -> case window' of
    Window Timing.When Window.NonFast -> matchWho iid iid whoMatcher
    Window Timing.When (Window.DuringTurn who) -> matchWho iid who whoMatcher
    Window Timing.When Window.FastPlayerWindow -> do
      miid <- selectOne Matcher.TurnInvestigator
      pure $ Just iid == miid
    _ -> pure False
  Matcher.OrWindowMatcher matchers ->
    anyM (windowMatches iid source window') matchers
  Matcher.EnemySpawns timingMatcher whereMatcher enemyMatcher ->
    case window' of
      Window t (Window.EnemySpawns enemyId locationId) | t == timingMatcher ->
        liftA2
          (&&)
          (enemyMatches enemyId enemyMatcher)
          (locationMatches iid source window' locationId whereMatcher)
      _ -> pure False
  Matcher.EnemyWouldAttack timingMatcher whoMatcher enemyAttackMatcher enemyMatcher
    -> case window' of
      Window t (Window.EnemyWouldAttack who enemyId enemyAttackType)
        | timingMatcher == t -> andM
          [ matchWho iid who whoMatcher
          , enemyMatches enemyId enemyMatcher
          , pure $ enemyAttackMatches enemyAttackType enemyAttackMatcher
          ]
      _ -> pure False
  Matcher.EnemyAttacks timingMatcher whoMatcher enemyAttackMatcher enemyMatcher
    -> case window' of
      Window t (Window.EnemyAttacks who enemyId enemyAttackType)
        | timingMatcher == t -> andM
          [ matchWho iid who whoMatcher
          , enemyMatches enemyId enemyMatcher
          , pure $ enemyAttackMatches enemyAttackType enemyAttackMatcher
          ]
      _ -> pure False
  Matcher.EnemyAttacksEvenIfCancelled timingMatcher whoMatcher enemyAttackMatcher enemyMatcher
    -> case window' of
      Window t (Window.EnemyAttacksEvenIfCancelled who enemyId enemyAttackType)
        | timingMatcher == t -> andM
          [ matchWho iid who whoMatcher
          , enemyMatches enemyId enemyMatcher
          , pure $ enemyAttackMatches enemyAttackType enemyAttackMatcher
          ]
      _ -> pure False
  Matcher.EnemyAttacked timingMatcher whoMatcher sourceMatcher enemyMatcher ->
    case window' of
      Window t (Window.EnemyAttacked who attackSource enemyId)
        | timingMatcher == t -> andM
          [ matchWho iid who whoMatcher
          , enemyMatches enemyId enemyMatcher
          , sourceMatches attackSource sourceMatcher
          ]
      _ -> pure False
  Matcher.EnemyEvaded timingMatcher whoMatcher enemyMatcher -> case window' of
    Window t (Window.EnemyEvaded who enemyId) | timingMatcher == t -> liftA2
      (&&)
      (enemyMatches enemyId enemyMatcher)
      (matchWho iid who whoMatcher)
    _ -> pure False
  Matcher.EnemyEngaged timingMatcher whoMatcher enemyMatcher -> case window' of
    Window t (Window.EnemyEngaged who enemyId) | timingMatcher == t -> liftA2
      (&&)
      (enemyMatches enemyId enemyMatcher)
      (matchWho iid who whoMatcher)
    _ -> pure False
  Matcher.MythosStep mythosStepMatcher -> case window' of
    Window t Window.AllDrawEncounterCard | t == Timing.When ->
      pure $ mythosStepMatcher == Matcher.WhenAllDrawEncounterCard
    Window t Window.AfterCheckDoomThreshold | t == Timing.When ->
      pure $ mythosStepMatcher == Matcher.AfterCheckDoomThreshold
    _ -> pure False
  Matcher.WouldRevealChaosToken whenMatcher whoMatcher -> case window' of
    Window t (Window.WouldRevealChaosToken _ who) | whenMatcher == t ->
      matchWho iid who whoMatcher
    _ -> pure False
  Matcher.RevealChaosToken whenMatcher whoMatcher tokenMatcher ->
    case window' of
      Window t (Window.RevealToken who token) | whenMatcher == t -> liftA2
        (&&)
        (matchWho iid who whoMatcher)
        (matchToken who token tokenMatcher)
      _ -> pure False
  Matcher.AddedToVictory timingMatcher cardMatcher -> case window' of
    Window t (Window.AddedToVictory card) | timingMatcher == t ->
      pure $ cardMatch card cardMatcher
    _ -> pure False
  Matcher.AssetDefeated timingMatcher defeatedByMatcher assetMatcher ->
    case window' of
      Window t (Window.AssetDefeated assetId defeatedBy) | timingMatcher == t ->
        andM
          [ member assetId <$> select assetMatcher
          , defeatedByMatches defeatedBy defeatedByMatcher
          ]
      _ -> pure False
  Matcher.EnemyDefeated timingMatcher whoMatcher enemyMatcher ->
    case window' of
      Window t (Window.EnemyDefeated (Just who) enemyId) | timingMatcher == t -> liftA2
        (&&)
        (enemyMatches enemyId enemyMatcher)
        (matchWho iid who whoMatcher)
      _ -> pure False
  Matcher.EnemyEnters timingMatcher whereMatcher enemyMatcher ->
    case window' of
      Window t (Window.EnemyEnters enemyId lid) | timingMatcher == t -> liftA2
        (&&)
        (enemyMatches enemyId enemyMatcher)
        (locationMatches iid source window' lid whereMatcher)
      _ -> pure False
  Matcher.EnemyLeaves timingMatcher whereMatcher enemyMatcher ->
    case window' of
      Window t (Window.EnemyLeaves enemyId lid) | timingMatcher == t -> liftA2
        (&&)
        (enemyMatches enemyId enemyMatcher)
        (locationMatches iid source window' lid whereMatcher)
      _ -> pure False
  Matcher.ChosenRandomLocation timingMatcher whereMatcher -> case window' of
    Window t (Window.ChosenRandomLocation lid) | timingMatcher == t ->
      locationMatches iid source window' lid whereMatcher
    _ -> pure False
  Matcher.EnemyWouldBeDefeated timingMatcher enemyMatcher -> case window' of
    Window t (Window.EnemyWouldBeDefeated enemyId) | timingMatcher == t ->
      enemyMatches enemyId enemyMatcher
    _ -> pure False
  Matcher.EnemyWouldReady timingMatcher enemyMatcher -> case window' of
    Window t (Window.WouldReady (EnemyTarget enemyId)) | timingMatcher == t ->
      enemyMatches enemyId enemyMatcher
    _ -> pure False
  Matcher.FastPlayerWindow -> case window' of
    Window Timing.When Window.FastPlayerWindow -> pure True
    _ -> pure False
  Matcher.DealtDamageOrHorror whenMatcher sourceMatcher whoMatcher ->
    case whoMatcher of
      Matcher.You -> case window' of
        Window t (Window.WouldTakeDamageOrHorror source' (InvestigatorTarget iid') _ _)
          | t == whenMatcher
          -> andM
            [matchWho iid iid' whoMatcher, sourceMatches source' sourceMatcher]
        _ -> pure False
      _ -> pure False
  Matcher.DealtDamage whenMatcher sourceMatcher whoMatcher -> case window' of
    Window t (Window.DealtDamage source' _ (InvestigatorTarget iid'))
      | t == whenMatcher -> andM
        [matchWho iid iid' whoMatcher, sourceMatches source' sourceMatcher]
    _ -> pure False
  Matcher.DealtHorror whenMatcher sourceMatcher whoMatcher -> case window' of
    Window t (Window.DealtHorror source' (InvestigatorTarget iid'))
      | t == whenMatcher -> andM
        [matchWho iid iid' whoMatcher, sourceMatches source' sourceMatcher]
    _ -> pure False
  Matcher.AssignedHorror whenMatcher whoMatcher targetListMatcher ->
    case window' of
      Window t (Window.AssignedHorror _ who targets) | t == whenMatcher ->
        liftA2
          (&&)
          (matchWho iid who whoMatcher)
          (targetListMatches targets targetListMatcher)
      _ -> pure False
  Matcher.AssetDealtDamage timingMatcher sourceMatcher assetMatcher ->
    case window' of
      Window t (Window.DealtDamage source' _ (AssetTarget aid))
        | t == timingMatcher
        -> andM
          [ member aid <$> select assetMatcher
          , sourceMatches source' sourceMatcher
          ]
      _ -> pure False
  Matcher.EnemyDealtDamage timingMatcher damageEffectMatcher enemyMatcher sourceMatcher
    -> case window' of
      Window t (Window.DealtDamage source' damageEffect (EnemyTarget eid))
        | t == timingMatcher -> andM
          [ damageEffectMatches damageEffect damageEffectMatcher
          , member eid <$> select enemyMatcher
          , sourceMatches source' sourceMatcher
          ]
      _ -> pure False
  Matcher.EnemyDealtExcessDamage timingMatcher damageEffectMatcher enemyMatcher sourceMatcher
    -> case window' of
      Window t (Window.DealtExcessDamage source' damageEffect (EnemyTarget eid) _)
        | t == timingMatcher
        -> andM
          [ damageEffectMatches damageEffect damageEffectMatcher
          , member eid <$> select enemyMatcher
          , sourceMatches source' sourceMatcher
          ]
      _ -> pure False
  Matcher.EnemyTakeDamage timingMatcher damageEffectMatcher enemyMatcher sourceMatcher
    -> case window' of
      Window t (Window.TakeDamage source' damageEffect (EnemyTarget eid))
        | t == timingMatcher -> andM
          [ damageEffectMatches damageEffect damageEffectMatcher
          , member eid <$> select enemyMatcher
          , sourceMatches source' sourceMatcher
          ]
      _ -> pure False
  Matcher.DiscoverClues whenMatcher whoMatcher whereMatcher valueMatcher ->
    case window' of
      Window t (Window.DiscoverClues who lid n) | whenMatcher == t -> andM
        [ matchWho iid who whoMatcher
        , locationMatches iid source window' lid whereMatcher
        , gameValueMatches n valueMatcher
        ]
      _ -> pure False
  Matcher.GainsClues whenMatcher whoMatcher valueMatcher -> case window' of
    Window t (Window.GainsClues who n) | whenMatcher == t ->
      andM [matchWho iid who whoMatcher, gameValueMatches n valueMatcher]
    _ -> pure False
  Matcher.DiscoveringLastClue whenMatcher whoMatcher whereMatcher ->
    case window' of
      Window t (Window.DiscoveringLastClue who lid) | whenMatcher == t -> liftA2
        (&&)
        (matchWho iid who whoMatcher)
        (locationMatches iid source window' lid whereMatcher)
      _ -> pure False
  Matcher.LastClueRemovedFromAsset whenMatcher assetMatcher -> case window' of
    Window t (Window.LastClueRemovedFromAsset aid) | whenMatcher == t ->
      member aid <$> select assetMatcher
    _ -> pure False
  Matcher.DrawsCards whenMatcher whoMatcher valueMatcher -> case window' of
    Window t (Window.DrawCards who cards) | whenMatcher == t ->
      andM
        [ matchWho iid who whoMatcher
        , gameValueMatches (length cards) valueMatcher
        ]
    _ -> pure False
  Matcher.DrawCard whenMatcher whoMatcher cardMatcher deckMatcher ->
    case window' of
      Window t (Window.DrawCard who card deck) | whenMatcher == t -> andM
        [ matchWho iid who whoMatcher
        , case cardMatcher of
          Matcher.BasicCardMatch baseMatcher ->
            pure $ cardMatch card baseMatcher
          _ -> member card <$> select cardMatcher
        , deckMatch iid deck deckMatcher
        ]
      _ -> pure False
  Matcher.DeckHasNoCards whenMatcher whoMatcher -> case window' of
    Window t (Window.DeckHasNoCards who) | whenMatcher == t ->
      matchWho iid who whoMatcher
    _ -> pure False
  Matcher.PlayCard whenMatcher whoMatcher cardMatcher -> case window' of
    Window t (Window.PlayCard who card) | whenMatcher == t -> liftA2
      (&&)
      (matchWho iid who whoMatcher)
      (member card <$> select cardMatcher)
    _ -> pure False
  Matcher.AssetEntersPlay timingMatcher assetMatcher -> case window' of
    Window t (Window.EnterPlay (AssetTarget aid)) | t == timingMatcher ->
      member aid <$> select assetMatcher
    _ -> pure False
  Matcher.AssetLeavesPlay timingMatcher assetMatcher -> case window' of
    Window t (Window.LeavePlay (AssetTarget aid)) | t == timingMatcher ->
      member aid <$> select assetMatcher
    _ -> pure False
  Matcher.LocationLeavesPlay timingMatcher locationMatcher -> case window' of
    Window t (Window.LeavePlay (LocationTarget aid)) | t == timingMatcher ->
      member aid <$> select locationMatcher
    _ -> pure False
  Matcher.EnemyLeavesPlay timingMatcher enemyMatcher -> case window' of
    Window t (Window.LeavePlay (EnemyTarget eid)) | t == timingMatcher ->
      member eid <$> select enemyMatcher
    _ -> pure False
  Matcher.Explored timingMatcher whoMatcher resultMatcher -> case window' of
    Window t (Window.Explored who result) | timingMatcher == t -> andM
      [ matchWho iid who whoMatcher
      , case resultMatcher of
        Matcher.SuccessfulExplore locationMatcher -> case result of
          Window.Success lid -> lid <=~> locationMatcher
          Window.Failure _ -> pure False
        Matcher.FailedExplore cardMatcher -> case result of
          Window.Success _ -> pure False
          Window.Failure card -> pure $ cardMatch card cardMatcher
      ]
    _ -> pure False
  Matcher.AttemptExplore timingMatcher whoMatcher -> case window' of
    Window t (Window.AttemptExplore who) | timingMatcher == t ->
      matchWho iid who whoMatcher
    _ -> pure False

matchWho
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> InvestigatorId
  -> Matcher.InvestigatorMatcher
  -> m Bool
matchWho iid who Matcher.You = pure $ iid == who
matchWho iid who Matcher.NotYou = pure $ iid /= who
matchWho _ _ Matcher.Anyone = pure True
matchWho iid who (Matcher.InvestigatorAt matcher) = do
  mlid <- field InvestigatorLocation iid
  member who <$> select
    (Matcher.InvestigatorAt $ Matcher.replaceYourLocation iid mlid matcher)
matchWho iid who matcher = member who <$> (select =<< replaceMatchWhoLocations iid matcher)
  where
    replaceMatchWhoLocations iid' = \case
      Matcher.InvestigatorAt matcher' -> do
        mlid <- field InvestigatorLocation iid'
        pure $ Matcher.InvestigatorAt $ Matcher.replaceYourLocation iid mlid matcher'
      Matcher.HealableInvestigator damageType inner -> do
        Matcher.HealableInvestigator damageType <$> replaceMatchWhoLocations iid' inner
      other -> pure other

gameValueMatches
  :: (Monad m, HasGame m) => Int -> Matcher.ValueMatcher -> m Bool
gameValueMatches n = \case
  Matcher.AnyValue -> pure True
  Matcher.LessThan gv -> (n <) <$> getPlayerCountValue gv
  Matcher.GreaterThan gv -> (n >) <$> getPlayerCountValue gv
  Matcher.LessThanOrEqualTo gv -> (n <=) <$> getPlayerCountValue gv
  Matcher.GreaterThanOrEqualTo gv -> (n >=) <$> getPlayerCountValue gv
  Matcher.EqualTo gv -> (n ==) <$> getPlayerCountValue gv

skillTestValueMatches
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Int
  -> Maybe Action
  -> SkillType
  -> Matcher.SkillTestValueMatcher
  -> m Bool
skillTestValueMatches iid n maction skillType = \case
  Matcher.AnySkillTestValue -> pure True
  Matcher.SkillTestGameValue valueMatcher -> gameValueMatches n valueMatcher
  Matcher.GreaterThanBaseValue -> do
    baseSkill <- baseSkillValueFor skillType maction [] iid
    pure $ n > baseSkill

targetTraits :: (HasCallStack, Monad m, HasGame m) => Target -> m (HashSet Trait)
targetTraits = \case
  ActDeckTarget -> pure mempty
  ActTarget _ -> pure mempty
  AfterSkillTestTarget -> pure mempty
  AgendaDeckTarget -> pure mempty
  AgendaTarget _ -> pure mempty
  AssetTarget aid -> field AssetTraits aid

  CardCodeTarget _ -> pure mempty
  CardIdTarget _ -> pure mempty
  EffectTarget _ -> pure mempty

  EnemyTarget eid -> field EnemyTraits eid
  EventTarget eid -> field EventTraits eid


  InvestigatorTarget iid -> field InvestigatorTraits iid
  LocationTarget lid -> field LocationTraits lid

  ProxyTarget t _ -> targetTraits t
  ResourceTarget -> pure mempty

  ScenarioTarget -> pure mempty
  SkillTarget sid -> field SkillTraits sid
  SkillTestTarget{} -> pure mempty
  TreacheryTarget tid -> field TreacheryTraits tid

  StoryTarget _ -> pure mempty
  TestTarget -> pure mempty
  TokenTarget _ -> pure mempty
  YouTarget -> selectJust Matcher.You >>= field InvestigatorTraits

  InvestigatorHandTarget _ -> pure mempty
  InvestigatorDiscardTarget _ -> pure mempty
  SetAsideLocationsTarget _ -> pure mempty
  EncounterDeckTarget -> pure mempty
  ScenarioDeckTarget -> pure mempty
  CardTarget c -> pure $ toTraits c
  SearchedCardTarget _ -> pure mempty
  SkillTestInitiatorTarget _ -> pure mempty
  PhaseTarget _ -> pure mempty
  TokenFaceTarget _ -> pure mempty
  InvestigationTarget _ _ -> pure mempty
  AgendaMatcherTarget _ -> pure mempty
  CampaignTarget -> pure mempty
  AbilityTarget _ _ -> pure mempty

sourceTraits
  :: (HasCallStack, Monad m, HasGame m) => Source -> m (HashSet Trait)
sourceTraits = \case
  AbilitySource s _ -> sourceTraits s
  ActDeckSource -> pure mempty
  ActSource _ -> pure mempty
  AfterSkillTestSource -> pure mempty
  AgendaDeckSource -> pure mempty
  AgendaSource _ -> pure mempty
  AgendaMatcherSource _ -> pure mempty
  AssetMatcherSource _ -> pure mempty
  AssetSource aid -> field AssetTraits aid

  CardCodeSource _ -> pure mempty
  CardIdSource _ -> pure mempty
  DeckSource -> pure mempty
  EffectSource _ -> pure mempty
  EmptyDeckSource -> pure mempty
  EncounterCardSource _ -> pure mempty
  EnemyAttackSource _ -> pure mempty

  EnemySource eid -> field EnemyTraits eid
  EventSource eid -> field EventTraits eid

  GameSource -> pure mempty

  InvestigatorSource iid -> field InvestigatorTraits iid
  LocationSource lid -> field LocationTraits lid

  PlayerCardSource _ -> pure mempty
  ProxySource s _ -> sourceTraits s
  ResourceSource -> pure mempty

  ScenarioSource -> pure mempty
  SkillSource sid -> field SkillTraits sid
  SkillTestSource{} -> pure mempty
  TreacherySource tid -> field TreacheryTraits tid

  StorySource _ -> pure mempty
  TestSource traits -> pure traits
  TokenEffectSource _ -> pure mempty
  TokenSource _ -> pure mempty
  YouSource -> selectJust Matcher.You >>= field InvestigatorTraits
  LocationMatcherSource _ -> pure mempty
  EnemyMatcherSource _ -> pure mempty
  CampaignSource -> pure mempty

  ThisCard -> error "can not get traits"
  CardCostSource _ -> pure mempty

getSourceController :: (Monad m, HasGame m) => Source -> m (Maybe InvestigatorId)
getSourceController = \case
  AssetSource aid -> selectAssetController aid
  EventSource eid -> selectEventController eid
  SkillSource sid -> selectSkillController sid
  InvestigatorSource iid -> pure $ Just iid
  _ -> pure Nothing

sourceMatches
  :: (HasCallStack, Monad m, HasGame m)
  => Source
  -> Matcher.SourceMatcher
  -> m Bool
sourceMatches s = \case
  Matcher.SourceIsCancelable sm -> case s of
    CardCostSource _ -> pure False
    _ -> sourceMatches s sm
  Matcher.SourceIs s' -> pure $ s == s'
  Matcher.NotSource matcher -> not <$> sourceMatches s matcher
  Matcher.SourceMatchesAny ms -> anyM (sourceMatches s) ms
  Matcher.SourceWithTrait t -> elem t <$> sourceTraits s
  Matcher.SourceIsEnemyAttack em -> case s of
    EnemyAttackSource eid -> member eid <$> select em
    _ -> pure False
  Matcher.AnySource -> pure True
  Matcher.SourceMatches ms -> allM (sourceMatches s) ms
  Matcher.SourceOwnedBy whoMatcher -> case s of
    AssetSource aid -> do
      mControllerId <- selectAssetController aid
      case mControllerId of
        Just iid' -> member iid' <$> select whoMatcher
        _ -> pure False
    EventSource eid -> do
      mControllerId <- fromJustNote "must have a controller"
        <$> selectEventController eid
      member mControllerId <$> select whoMatcher
    SkillSource sid -> do
      mControllerId <- fromJustNote "must have a controller"
        <$> selectSkillController sid
      member mControllerId <$> select whoMatcher
    InvestigatorSource iid -> member iid <$> select whoMatcher
    _ -> pure False
  Matcher.SourceIsType t -> pure $ case t of
    AssetType -> case s of
      AssetSource _ -> True
      _ -> False
    EventType -> case s of
      EventSource _ -> True
      _ -> False
    SkillType -> case s of
      SkillSource _ -> True
      _ -> False
    PlayerTreacheryType -> case s of
      TreacherySource _ -> True
      _ -> False
    PlayerEnemyType -> case s of
      EnemySource _ -> True
      _ -> False
    TreacheryType -> case s of
      TreacherySource _ -> True
      _ -> False
    EnemyType -> case s of
      EnemySource _ -> True
      _ -> False
    LocationType -> case s of
      LocationSource _ -> True
      _ -> False
    EncounterAssetType -> case s of
      AssetSource _ -> True
      _ -> False
    ActType -> case s of
      ActSource _ -> True
      _ -> False
    AgendaType -> case s of
      AgendaSource _ -> True
      _ -> False
    StoryType -> case s of
      StorySource _ -> True
      _ -> False
    InvestigatorType -> case s of
      InvestigatorSource _ -> True
      _ -> False
    ScenarioType -> case s of
      ScenarioSource -> True
      _ -> False
  Matcher.EncounterCardSource -> pure $ case s of
    ActSource _ -> True
    AgendaSource _ -> True
    EnemySource _ -> True
    LocationSource _ -> True
    TreacherySource _ -> True
    _ -> False

targetMatches
  :: (Monad m, HasGame m) => Target -> Matcher.TargetMatcher -> m Bool
targetMatches s = \case
  Matcher.TargetMatchesAny ms -> anyM (targetMatches s) ms
  Matcher.TargetIs s' -> pure $ s == s'
  Matcher.AnyTarget -> pure True
  Matcher.TargetMatches ms -> allM (targetMatches s) ms

enemyMatches
  :: (Monad m, HasGame m) => EnemyId -> Matcher.EnemyMatcher -> m Bool
enemyMatches !enemyId !mtchr = member enemyId <$> select mtchr

matches :: (Monad m, HasGame m, Query a) => QueryElement a -> a -> m Bool
matches a matcher = member a <$> select matcher

(<=~>) :: (Monad m, HasGame m, Query a) => QueryElement a -> a -> m Bool
(<=~>) = matches

(<!=~>) :: (Monad m, HasGame m, Query a) => QueryElement a -> a -> m Bool
(<!=~>) el q = not <$> matches el q

locationMatches
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> Window
  -> LocationId
  -> Matcher.LocationMatcher
  -> m Bool
locationMatches investigatorId source window locationId matcher' = do
  mlid <- field InvestigatorLocation investigatorId
  let matcher = Matcher.replaceYourLocation investigatorId mlid matcher'
  case matcher of
    -- special cases
    Matcher.NotLocation m ->
      not <$> locationMatches investigatorId source window locationId m
    Matcher.LocationWithDefeatedEnemyThisRound -> locationId <=~> matcher
    Matcher.LocationWithDiscoverableCluesBy _ -> locationId <=~> matcher
    Matcher.LocationWithoutModifier _ -> locationId <=~> matcher
    Matcher.LocationWithModifier _ -> locationId <=~> matcher
    Matcher.IsIchtacasDestination -> locationId <=~> matcher
    Matcher.SingleSidedLocation -> locationId <=~> matcher
    Matcher.LocationWithEnemy enemyMatcher -> selectAny
      (Matcher.EnemyAt (Matcher.LocationWithId locationId) <> enemyMatcher)
    Matcher.LocationWithAsset assetMatcher -> selectAny
      (Matcher.AssetAt (Matcher.LocationWithId locationId) <> assetMatcher)
    Matcher.LocationWithInvestigator whoMatcher -> selectAny
      (Matcher.InvestigatorAt (Matcher.LocationWithId locationId) <> whoMatcher)
    Matcher.LocationWithoutTreachery treacheryMatcher -> do
      selectNone
        (Matcher.TreacheryAt (Matcher.LocationWithId locationId)
        <> treacheryMatcher
        )
    Matcher.LocationWithTreachery treacheryMatcher -> do
      selectAny
        (Matcher.TreacheryAt (Matcher.LocationWithId locationId)
        <> treacheryMatcher
        )

    -- normal cases
    Matcher.LocationNotInPlay -> locationId <=~> matcher
    Matcher.LocationWithLabel _ -> locationId <=~> matcher
    Matcher.LocationWithTitle _ -> locationId <=~> matcher
    Matcher.LocationWithFullTitle _ _ -> locationId <=~> matcher
    Matcher.LocationWithSymbol _ -> locationId <=~> matcher
    Matcher.LocationWithUnrevealedTitle _ -> locationId <=~> matcher
    Matcher.LocationWithId _ -> locationId <=~> matcher
    Matcher.LocationIs _ -> locationId <=~> matcher
    Matcher.Anywhere -> locationId <=~> matcher
    Matcher.Nowhere -> locationId <=~> matcher
    Matcher.LocationCanBeFlipped -> locationId <=~> matcher
    Matcher.BlockedLocation -> locationId <=~> matcher
    Matcher.EmptyLocation -> locationId <=~> matcher
    Matcher.LocationWithoutInvestigators -> locationId <=~> matcher
    Matcher.LocationWithoutEnemies -> locationId <=~> matcher
    Matcher.AccessibleLocation -> locationId <=~> matcher
    Matcher.AccessibleFrom _ -> locationId <=~> matcher
    Matcher.AccessibleTo _ -> locationId <=~> matcher
    Matcher.ConnectedFrom _ -> locationId <=~> matcher
    Matcher.ConnectedTo _ -> locationId <=~> matcher
    Matcher.ConnectedLocation -> locationId <=~> matcher
    Matcher.RevealedLocation -> locationId <=~> matcher
    Matcher.UnrevealedLocation -> locationId <=~> matcher
    Matcher.FarthestLocationFromYou _ -> locationId <=~> matcher
    Matcher.FarthestLocationFromLocation _ _ -> locationId <=~> matcher
    Matcher.NearestLocationToLocation _ _ -> locationId <=~> matcher
    Matcher.FarthestLocationFromAll _ -> locationId <=~> matcher
    Matcher.NearestLocationToYou _ -> locationId <=~> matcher
    Matcher.LocationWithTrait _ -> locationId <=~> matcher
    Matcher.LocationWithoutTrait _ -> locationId <=~> matcher
    Matcher.LocationInDirection _ _ -> locationId <=~> matcher
    Matcher.ClosestPathLocation _ _ -> locationId <=~> matcher
    Matcher.LocationWithoutClues -> locationId <=~> matcher

    Matcher.LocationWithDistanceFrom _ _ -> locationId <=~> matcher
    Matcher.LocationWithClues valueMatcher ->
      (`gameValueMatches` valueMatcher) =<< field LocationClues locationId
    Matcher.LocationWithDoom valueMatcher ->
      (`gameValueMatches` valueMatcher) =<< field LocationDoom locationId
    Matcher.LocationWithHorror valueMatcher ->
      (`gameValueMatches` valueMatcher) =<< field LocationHorror locationId
    Matcher.LocationWithMostClues locationMatcher -> member locationId
      <$> select (Matcher.LocationWithMostClues locationMatcher)
    Matcher.LocationWithResources valueMatcher ->
      (`gameValueMatches` valueMatcher) =<< field LocationResources locationId
    Matcher.LocationLeavingPlay -> case window of
      Window _ (Window.LeavePlay (LocationTarget lid)) ->
        pure $ locationId == lid
      _ -> error "invalid window for LocationLeavingPlay"
    Matcher.SameLocation -> do
      mlid' <- case source of
        EnemySource eid -> field EnemyLocation eid
        AssetSource aid -> field AssetLocation aid
        _ -> error $ "can't detect same location for source " <> show source
      pure $ Just locationId == mlid'
    Matcher.YourLocation -> do
      yourLocationId <- field InvestigatorLocation investigatorId
      pure $ Just locationId == yourLocationId
    Matcher.ThisLocation -> case source of
      (LocationSource lid) -> pure $ lid == locationId
      (ProxySource (LocationSource lid) _) -> pure $ lid == locationId
      _ -> error "Invalid source for ThisLocation"
    Matcher.NotYourLocation -> do
      yourLocationId <- field InvestigatorLocation investigatorId
      pure $ Just locationId /= yourLocationId
    Matcher.LocationMatchAll ms ->
      allM (locationMatches investigatorId source window locationId) ms
    Matcher.LocationMatchAny ms ->
      anyM (locationMatches investigatorId source window locationId) ms
    Matcher.FirstLocation ms ->
      anyM (locationMatches investigatorId source window locationId) ms -- a bit weird here since first means nothing
    Matcher.InvestigatableLocation -> do
      modifiers <- getModifiers (LocationTarget locationId)
      pure $ CannotInvestigate `notElem` modifiers

skillTestMatches
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Source
  -> SkillTest
  -> Matcher.SkillTestMatcher
  -> m Bool
skillTestMatches iid source st = \case
  Matcher.NotSkillTest matcher ->
    not <$> skillTestMatches iid source st matcher
  Matcher.AnySkillTest -> pure True
  Matcher.SkillTestWasFailed -> pure $ case skillTestResult st of
    FailedBy _ _ -> True
    _ -> False
  Matcher.YourSkillTest matcher -> liftA2
    (&&)
    (pure $ skillTestInvestigator st == iid)
    (skillTestMatches iid source st matcher)
  Matcher.UsingThis -> pure $ source == skillTestSource st
  Matcher.SkillTestSourceMatches sourceMatcher ->
    sourceMatches (skillTestSource st) sourceMatcher
  Matcher.WhileInvestigating locationMatcher -> case skillTestAction st of
    Just Action.Investigate -> case skillTestTarget st of
      LocationTarget lid -> member lid <$> select locationMatcher
      ProxyTarget (LocationTarget lid) _ ->
        member lid <$> select locationMatcher
      _ -> pure False
    _ -> pure False
  Matcher.SkillTestOnTreachery treacheryMatcher -> case skillTestSource st of
    TreacherySource tid -> member tid <$> select treacheryMatcher
    _ -> pure False
  Matcher.WhileAttackingAnEnemy enemyMatcher -> case skillTestAction st of
    Just Action.Fight -> case skillTestTarget st of
      EnemyTarget eid -> member eid <$> select enemyMatcher
      _ -> pure False
    _ -> pure False
  Matcher.WhileEvadingAnEnemy enemyMatcher -> case skillTestAction st of
    Just Action.Evade -> case skillTestTarget st of
      EnemyTarget eid -> member eid <$> select enemyMatcher
      _ -> pure False
    _ -> pure False
  Matcher.SkillTestWithSkill sk -> selectAny sk
  Matcher.SkillTestWithSkillType sType -> pure $ skillTestSkillType st == sType
  Matcher.SkillTestAtYourLocation -> do
    mlid1 <- field InvestigatorLocation iid
    mlid2 <- field InvestigatorLocation $ skillTestInvestigator st
    case (mlid1, mlid2) of
      (Just lid1, Just lid2) -> pure $ lid1 == lid2
      _ -> pure False
  Matcher.SkillTestMatches ms -> allM (skillTestMatches iid source st) ms

matchToken
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> Token
  -> Matcher.TokenMatcher
  -> m Bool
matchToken _ = (<=~>)

matchPhase :: Monad m => Phase -> Matcher.PhaseMatcher -> m Bool
matchPhase p = \case
  Matcher.AnyPhase -> pure True
  Matcher.PhaseIs p' -> pure $ p == p'

getModifiedTokenFaces :: (Monad m, HasGame m) => [Token] -> m [TokenFace]
getModifiedTokenFaces tokens = flip
  concatMapM
  tokens
  \token -> do
    modifiers' <- getModifiers (TokenTarget token)
    pure $ foldl' applyModifier [tokenFace token] modifiers'
 where
  applyModifier _ (TokenFaceModifier fs') = fs'
  applyModifier [f'] (ForcedTokenChange f fs) | f == f' = fs
  applyModifier fs _ = fs

cardListMatches
  :: (Monad m, HasGame m) => [Card] -> Matcher.CardListMatcher -> m Bool
cardListMatches cards = \case
  Matcher.AnyCards -> pure True
  Matcher.LengthIs valueMatcher -> gameValueMatches (length cards) valueMatcher
  Matcher.HasCard cardMatcher -> pure $ any (`cardMatch` cardMatcher) cards

targetListMatches
  :: (Monad m, HasGame m) => [Target] -> Matcher.TargetListMatcher -> m Bool
targetListMatches targets = \case
  Matcher.AnyTargetList -> pure True
  Matcher.HasTarget targetMatcher ->
    anyM (`targetMatches` targetMatcher) targets
  Matcher.ExcludesTarget targetMatcher ->
    noneM (`targetMatches` targetMatcher) targets

deckMatch
  :: (Monad m, HasGame m)
  => InvestigatorId
  -> DeckSignifier
  -> Matcher.DeckMatcher
  -> m Bool
deckMatch iid deckSignifier = \case
  Matcher.EncounterDeck -> pure $ deckSignifier == EncounterDeck
  Matcher.DeckOf investigatorMatcher -> matchWho iid iid investigatorMatcher
  Matcher.AnyDeck -> pure True

agendaMatches
  :: (Monad m, HasGame m) => AgendaId -> Matcher.AgendaMatcher -> m Bool
agendaMatches !agendaId !mtchr = member agendaId <$> select mtchr

actionMatches :: Monad m => Action -> Matcher.ActionMatcher -> m Bool
actionMatches _ Matcher.AnyAction = pure True
actionMatches a (Matcher.ActionIs a') = pure $ a == a'
actionMatches a (Matcher.ActionOneOf as) = anyM (actionMatches a) as

skillTypeMatches :: SkillType -> Matcher.SkillTypeMatcher -> Bool
skillTypeMatches st = \case
  Matcher.AnySkillType -> True
  Matcher.NotSkillType st' -> st /= st'
  Matcher.IsSkillType st' -> st == st'

enemyAttackMatches :: EnemyAttackType -> Matcher.EnemyAttackMatcher -> Bool
enemyAttackMatches atkType = \case
  Matcher.AnyEnemyAttack -> True
  Matcher.AttackOfOpportunityAttack -> atkType == AttackOfOpportunity

damageEffectMatches
  :: Monad m => DamageEffect -> Matcher.DamageEffectMatcher -> m Bool
damageEffectMatches a = \case
  Matcher.AnyDamageEffect -> pure True
  Matcher.AttackDamageEffect -> pure $ a == AttackDamageEffect
  Matcher.NonAttackDamageEffect -> pure $ a == NonAttackDamageEffect

spawnAtOneOf :: InvestigatorId -> EnemyId -> [LocationId] -> GameT ()
spawnAtOneOf iid eid targetLids = do
  locations' <- select Matcher.Anywhere
  case setToList (setFromList targetLids `intersection` locations') of
    [] -> push (Discard (EnemyTarget eid))
    [lid] -> pushAll (resolve $ EnemySpawn Nothing lid eid)
    lids -> push
      (chooseOne
        iid
        [ TargetLabel
            (LocationTarget lid)
            (resolve $ EnemySpawn Nothing lid eid)
        | lid <- lids
        ]
      )

sourceCanDamageEnemy :: (Monad m, HasGame m) => EnemyId -> Source -> m Bool
sourceCanDamageEnemy eid source = do
  modifiers' <- getModifiers (EnemyTarget eid)
  not <$> anyM prevents modifiers'
 where
  prevents = \case
    CannotBeDamagedByPlayerSourcesExcept matcher -> not <$> sourceMatches
      source
      (Matcher.SourceMatchesAny [Matcher.EncounterCardSource, matcher])
    CannotBeDamagedByPlayerSources matcher -> sourceMatches
      source
      (Matcher.SourceMatchesAny [Matcher.EncounterCardSource, matcher])
    CannotBeDamaged -> pure True
    _ -> pure False

getCanShuffleDeck :: (Monad m, HasGame m) => InvestigatorId -> m Bool
getCanShuffleDeck iid = do
  modifiers <- getModifiers (InvestigatorTarget iid)
  pure $ CannotManipulateDeck `notElem` modifiers

getDoomCount :: (Monad m, HasGame m) => m Int
getDoomCount = getSum . fold <$> sequence
  [ selectAgg Sum AssetDoom Matcher.AnyAsset
  , selectAgg Sum EnemyDoom Matcher.AnyEnemy
  , selectAgg Sum LocationDoom Matcher.Anywhere
  , selectAgg Sum TreacheryDoom Matcher.AnyTreachery
  , selectAgg Sum AgendaDoom Matcher.AnyAgenda
  , selectAgg Sum InvestigatorDoom Matcher.UneliminatedInvestigator
  ]

getPotentialSlots
  :: (Monad m, HasGame m, IsCard a) => a -> InvestigatorId -> m [SlotType]
getPotentialSlots card iid = do
  slots <- field InvestigatorSlots iid
  let
    slotTypesAndSlots :: [(SlotType, Slot)] =
      concatMap (\(slotType, slots') -> map (slotType, ) slots')
        $ mapToList slots
    passesRestriction = \case
      RestrictedSlot _ matcher _ -> cardMatch card matcher
      Slot{} -> True
  map fst
    <$> filterM
          (\(_, slot) -> if passesRestriction slot
            then case slotItem slot of
              Nothing -> pure True
              Just aid -> member aid <$> select Matcher.DiscardableAsset
            else pure False
          )
          slotTypesAndSlots

defeatedByMatches
  :: Monad m => DefeatedBy -> Matcher.DefeatedByMatcher -> m Bool
defeatedByMatches defeatedBy = \case
  Matcher.ByAnyOf xs -> anyM (defeatedByMatches defeatedBy) xs
  Matcher.ByHorror ->
    pure
      $ (defeatedBy == DefeatedByHorror)
      || (defeatedBy == DefeatedByDamageAndHorror)
  Matcher.ByDamage ->
    pure
      $ (defeatedBy == DefeatedByDamage)
      || (defeatedBy == DefeatedByDamageAndHorror)
  Matcher.ByOther -> pure $ defeatedBy == DefeatedByOther
  Matcher.ByAny -> pure True

additionalActionCovers
  :: (Monad m, HasGame m)
  => Source
  -> Maybe Action
  -> AdditionalAction
  -> m Bool
additionalActionCovers source maction = \case
  TraitRestrictedAdditionalAction t -> member t <$> sourceTraits source
  ActionRestrictedAdditionalAction a -> pure $ maction == Just a

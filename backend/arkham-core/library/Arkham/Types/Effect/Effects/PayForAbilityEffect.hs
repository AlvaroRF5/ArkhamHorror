module Arkham.Types.Effect.Effects.PayForAbilityEffect
  ( payForAbilityEffect
  , PayForAbilityEffect(..)
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Action hiding (Ability, TakenAction)
import qualified Arkham.Types.Action as Action
import Arkham.Types.AssetMatcher
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Effect.Attrs
import Arkham.Types.EffectId
import Arkham.Types.EffectMetadata
import Arkham.Types.Game.Helpers
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Query
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Trait

newtype PayForAbilityEffect = PayForAbilityEffect (EffectAttrs `With` Payment)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

payForAbilityEffect
  :: EffectId -> Maybe Ability -> Source -> Target -> PayForAbilityEffect
payForAbilityEffect eid mAbility source target =
  PayForAbilityEffect $ (`with` NoPayment) $ EffectAttrs
    { effectId = eid
    , effectSource = source
    , effectTarget = target
    , effectCardCode = Nothing
    , effectMetadata = EffectAbility <$> mAbility
    , effectTraits = mempty
    , effectWindow = Nothing
    }

instance HasModifiersFor env PayForAbilityEffect where
  getModifiersFor _ target (PayForAbilityEffect (With EffectAttrs {..} _))
    | target == effectTarget = case effectMetadata of
      Just (EffectModifiers modifiers) -> pure modifiers
      _ -> pure []
  getModifiersFor _ _ _ = pure []

matchTarget :: [Action] -> ActionTarget -> Action -> Bool
matchTarget takenActions (FirstOneOf as) action =
  action `elem` as && all (`notElem` takenActions) as
matchTarget _ (IsAction a) action = action == a
matchTarget _ (EnemyAction a _) action = action == a

getActionCostModifier
  :: ( MonadReader env m
     , HasModifiersFor env ()
     , HasList Action.TakenAction env InvestigatorId
     )
  => InvestigatorId
  -> Maybe Action
  -> m Int
getActionCostModifier _ Nothing = pure 0
getActionCostModifier iid (Just a) = do
  takenActions <- map unTakenAction <$> getList iid
  modifiers <- getModifiers (InvestigatorSource iid) (InvestigatorTarget iid)
  pure $ foldr (applyModifier takenActions) 0 modifiers
 where
  applyModifier takenActions (ActionCostOf match m) n =
    if matchTarget takenActions match a then n + m else n
  applyModifier _ _ n = n

countAdditionalActionPayments :: Payment -> Int
countAdditionalActionPayments AdditionalActionPayment = 1
countAdditionalActionPayments (Payments ps) =
  sum $ map countAdditionalActionPayments ps
countAdditionalActionPayments _ = 0

instance
  ( HasQueue env
  , HasSet InScenarioInvestigatorId env ()
  , HasCostPayment env
  , HasSet Trait env Source
  , HasModifiersFor env ()
  , HasList Action.TakenAction env InvestigatorId
  , HasCount ActionRemainingCount env InvestigatorId
  )
  => RunMessage env PayForAbilityEffect where
  runMessage msg e@(PayForAbilityEffect (attrs `With` payments)) = case msg of
    CreatedEffect eid (Just (EffectAbility Ability {..})) source (InvestigatorTarget iid)
      | eid == toId attrs
      -> do
        push (PayAbilityCostFinished source iid)
        e <$ case abilityType of
          ForcedAbility -> pure ()
          FastAbility cost ->
            push (PayAbilityCost abilitySource iid Nothing cost)
          ReactionAbility cost ->
            push (PayAbilityCost abilitySource iid Nothing cost)
          ActionAbility mAction cost ->
            if mAction
                `notElem` [ Just Action.Fight
                          , Just Action.Evade
                          , Just Action.Resign
                          , Just Action.Parley
                          ]
              then pushAll
                (PayAbilityCost abilitySource iid mAction cost
                : [ TakenAction iid action | action <- maybeToList mAction ]
                <> [ CheckAttackOfOpportunity iid False
                   | not abilityDoesNotProvokeAttacksOfOpportunity
                   ]
                )
              else pushAll
                (PayAbilityCost abilitySource iid mAction cost
                : [ TakenAction iid action | action <- maybeToList mAction ]
                )
    PayAbilityCost source iid mAction cost -> do
      let
        withPayment payment =
          pure $ PayForAbilityEffect (attrs `With` (payments <> payment))
      case cost of
        Costs xs ->
          e <$ pushAll [ PayAbilityCost source iid mAction x | x <- xs ]
        UpTo 0 _ -> pure e
        UpTo n cost' -> do
          canAfford <- getCanAffordCost iid source mAction cost'
          e <$ when
            canAfford
            (push $ chooseOne
              iid
              [ Label
                "Pay dynamic cost"
                [ PayAbilityCost source iid mAction cost'
                , PayAbilityCost source iid mAction (UpTo (n - 1) cost')
                ]
              , Label "Done with dynamic cost" []
              ]
            )
        ExhaustCost target -> do
          push (Exhaust target)
          withPayment $ ExhaustPayment [target]
        ExhaustAssetCost matcher -> do
          targets <- map AssetTarget <$> getSetList (matcher <> AssetReady)
          e <$ push
            (chooseOne
              iid
              [ TargetLabel
                  target
                  [PayAbilityCost source iid mAction (ExhaustCost target)]
              | target <- targets
              ]
            )
        DiscardCost target -> do
          push (Discard target)
          withPayment $ DiscardPayment [target]
        DiscardCardCost card -> do
          push (DiscardCard iid (toCardId card))
          withPayment $ DiscardCardPayment [card]
        ExileCost target -> do
          push (Exile target)
          withPayment $ ExilePayment [target]
        RemoveCost target -> do
          push (RemoveFromGame target)
          withPayment $ RemovePayment [target]
        DoomCost _ target x -> do
          push (PlaceDoom target x)
          withPayment $ DoomPayment x
        HorrorCost _ target x -> case target of
          InvestigatorTarget iid' | iid' == iid -> do
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
          AssetTarget aid -> do
            pushAll [AssetDamage aid source x 0, CheckDefeated source]
            withPayment $ DamagePayment x
          _ -> error "can't target for damage cost"
        ResourceCost x -> do
          push (SpendResources iid x)
          withPayment $ ResourcePayment x
        AdditionalActionsCost -> do
          actionRemainingCount <- unActionRemainingCount <$> getCount iid
          let currentlyPaid = countAdditionalActionPayments payments
          e <$ if actionRemainingCount == 0
            then pure ()
            else push
              (chooseOne
                iid
                [ Label
                  "Spend 1 additional action"
                  [ PayAbilityCost
                    (InvestigatorSource iid)
                    iid
                    Nothing
                    (ActionCost 1)
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
          costModifier <- getActionCostModifier iid mAction
          let modifiedActionCost = max 0 (x + costModifier)
          push (SpendActions iid source modifiedActionCost)
          withPayment $ ActionPayment x
        UseCost aid uType n -> do
          push (SpendUses (AssetTarget aid) uType n)
          withPayment $ UsesPayment n
        ClueCost x -> do
          push (InvestigatorSpendClues iid x)
          withPayment $ CluePayment x
        PlaceClueOnLocationCost x -> do
          push (InvestigatorPlaceCluesOnLocation iid x)
          withPayment $ CluePayment x
        GroupClueCost x Nothing -> do
          investigatorIds <- map unInScenarioInvestigatorId <$> getSetList ()
          totalClues <- getPlayerCountValue x
          push (SpendClues totalClues investigatorIds)
          withPayment $ CluePayment totalClues
        GroupClueCost x (Just locationMatcher) -> do
          mLocationId <- getId @(Maybe LocationId) locationMatcher
          totalClues <- getPlayerCountValue x
          case mLocationId of
            Just lid -> do
              iids <- getSetList @InvestigatorId lid
              push (SpendClues totalClues iids)
              withPayment $ CluePayment totalClues
            Nothing -> error "could not pay cost"
        HandDiscardCost x mPlayerCardType traits skillTypes -> do
          handCards <- mapMaybe (preview _PlayerCard . unHandCard)
            <$> getList iid
          let
            cards = filter
              (and . sequence
                [ maybe (const True) (==) mPlayerCardType
                . cdCardType
                . toCardDef
                , (|| null traits) . notNull . intersection traits . toTraits
                , (|| null skillTypes)
                . not
                . null
                . intersection (insertSet SkillWild skillTypes)
                . setFromList
                . cdSkills
                . toCardDef
                ]
              )
              handCards
          e <$ push
            (chooseN
              iid
              x
              [ TargetLabel
                  (CardIdTarget $ toCardId card)
                  [ PayAbilityCost
                      (InvestigatorSource iid)
                      iid
                      Nothing
                      (DiscardCardCost $ PlayerCard card)
                  ]
              | card <- cards
              ]
            )
        SkillIconCost x skillTypes -> do
          handCards <- mapMaybe (preview _PlayerCard . unHandCard)
            <$> getList iid
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
                  , PayAbilityCost
                    source
                    iid
                    mAction
                    (SkillIconCost (x - n) skillTypes)
                  ]
              )
              cards
          e <$ push (chooseOne iid cardMsgs)
        Free -> pure e
    PaidAbilityCost _ _ payment ->
      pure $ PayForAbilityEffect (attrs `with` (payments <> payment))
    PayAbilityCostFinished source iid -> case effectMetadata attrs of
      Just (EffectAbility Ability {..}) -> e <$ pushAll
        [ DisableEffect $ toId attrs
        , UseCardAbility iid source abilityMetadata abilityIndex payments
        ]
      _ -> e <$ push (DisableEffect $ toId attrs)
    _ -> PayForAbilityEffect . (`with` payments) <$> runMessage msg attrs

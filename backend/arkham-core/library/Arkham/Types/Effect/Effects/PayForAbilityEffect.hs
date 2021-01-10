module Arkham.Types.Effect.Effects.PayForAbilityEffect
  ( payForAbilityEffect
  , PayForAbilityEffect(..)
  ) where

import Arkham.Import

import Arkham.Types.Action hiding (Ability, TakenAction)
import qualified Arkham.Types.Action as Action
import Arkham.Types.Effect.Attrs
import Arkham.Types.Game.Helpers
import Arkham.Types.Trait

newtype PayForAbilityEffect = PayForAbilityEffect (Attrs `With` Payment)
  deriving newtype (Show, ToJSON, FromJSON)

payForAbilityEffect
  :: EffectId -> Maybe Ability -> Source -> Target -> PayForAbilityEffect
payForAbilityEffect eid mAbility source target =
  PayForAbilityEffect $ (`with` NoPayment) $ Attrs
    { effectId = eid
    , effectSource = source
    , effectTarget = target
    , effectCardCode = Nothing
    , effectMetadata = EffectAbility <$> mAbility
    , effectTraits = mempty
    }

instance HasModifiersFor env PayForAbilityEffect where
  getModifiersFor _ target (PayForAbilityEffect (With Attrs {..} _))
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
  modifiers <-
    map modifierType
      <$> getModifiersFor (InvestigatorSource iid) (InvestigatorTarget iid) ()
  pure $ foldr (applyModifier takenActions) 0 modifiers
 where
  applyModifier takenActions (ActionCostOf match m) n =
    if matchTarget takenActions match a then n + m else n
  applyModifier _ _ n = n

instance
  ( HasQueue env
  , HasSet InScenarioInvestigatorId env ()
  , HasCostPayment env
  , HasSet Trait env Source
  , HasModifiersFor env ()
  , HasList Action.TakenAction env InvestigatorId
  )
  => RunMessage env PayForAbilityEffect where
  runMessage msg e@(PayForAbilityEffect (attrs `With` payments)) = case msg of
    CreatedEffect eid (Just (EffectAbility Ability {..})) source (InvestigatorTarget iid)
      | eid == toId attrs
      -> do
        unshiftMessage (PayAbilityCostFinished source iid)
        e <$ case abilityType of
          ForcedAbility -> pure ()
          FastAbility cost ->
            unshiftMessage (PayAbilityCost abilitySource iid Nothing cost)
          ReactionAbility cost ->
            unshiftMessage (PayAbilityCost abilitySource iid Nothing cost)
          ActionAbility mAction cost ->
            if mAction
                `notElem` [ Just Action.Fight
                          , Just Action.Evade
                          , Just Action.Resign
                          , Just Action.Parley
                          ]
              then unshiftMessages
                (PayAbilityCost abilitySource iid mAction cost
                : [ TakenAction iid action | action <- maybeToList mAction ]
                <> [CheckAttackOfOpportunity iid False]
                )
              else unshiftMessages
                (PayAbilityCost abilitySource iid mAction cost
                : [ TakenAction iid action | action <- maybeToList mAction ]
                )
    PayAbilityCost source iid mAction cost -> case cost of
      Costs xs ->
        e <$ unshiftMessages [ PayAbilityCost source iid mAction x | x <- xs ]
      UpTo 0 _ -> pure e
      UpTo n cost' -> do
        canAfford <- getCanAffordCost iid source mAction cost'
        e <$ when
          canAfford
          (unshiftMessage $ chooseOne
            iid
            [ Label
              "Pay dynamic cost"
              [ PayAbilityCost source iid mAction cost'
              , PayAbilityCost source iid mAction (UpTo (n - 1) cost')
              ]
            , Label "Done with dynamic cost" []
            ]
          )
      ExhaustCost target -> e <$ unshiftMessage (Exhaust target)
      DiscardCost target -> e <$ unshiftMessage (Discard target)
      DiscardCardCost cid -> e <$ unshiftMessage (DiscardCard iid cid)
      HorrorCost _ target x -> case target of
        InvestigatorTarget iid' | iid' == iid ->
          e <$ unshiftMessage (InvestigatorAssignDamage iid source 0 x)
        AssetTarget aid -> e <$ unshiftMessage (AssetDamage aid source 0 x)
        _ -> error "can't target for horror cost"
      DamageCost _ target x -> case target of
        InvestigatorTarget iid' | iid' == iid ->
          e <$ unshiftMessage (InvestigatorAssignDamage iid source x 0)
        AssetTarget aid -> e <$ unshiftMessage (AssetDamage aid source x 0)
        _ -> error "can't target for damage cost"
      ResourceCost x -> e <$ unshiftMessage (SpendResources iid x)
      ActionCost x -> do
        costModifier <- getActionCostModifier iid mAction
        let modifiedActionCost = max 0 (x + costModifier)
        e <$ unshiftMessage (SpendActions iid source modifiedActionCost)
      UseCost aid uType n ->
        e <$ unshiftMessage (SpendUses (AssetTarget aid) uType n)
      ClueCost x -> e <$ unshiftMessage (InvestigatorSpendClues iid x)
      GroupClueCost x Nothing -> do
        investigatorIds <- map unInScenarioInvestigatorId <$> getSetList ()
        e <$ unshiftMessage (SpendClues x investigatorIds)
      GroupClueCost x (Just locationMatcher) -> do
        mLocationId <- getId @(Maybe LocationId) locationMatcher
        case mLocationId of
          Just lid -> do
            iids <- getSetList @InvestigatorId lid
            e <$ unshiftMessage (SpendClues x iids)
          Nothing -> error "could not pay cost"
      HandDiscardCost x mPlayerCardType traits -> do
        handCards <- mapMaybe (preview _PlayerCard . unHandCard) <$> getList iid
        let
          cards = filter
            (and . sequence
              [ maybe (const True) (==) mPlayerCardType . pcCardType
              , (|| null traits) . not . null . intersection traits . pcTraits
              ]
            )
            handCards
        e <$ unshiftMessage
          (chooseN iid x [ DiscardCard iid (getCardId card) | card <- cards ])
      Free -> pure e
    PayAbilityCostFinished source iid -> case effectMetadata attrs of
      Just (EffectAbility Ability {..}) -> e <$ unshiftMessages
        [ DisableEffect $ toId attrs
        , UseCardAbility iid source abilityMetadata abilityIndex payments
        ]
      _ -> e <$ unshiftMessage (DisableEffect $ toId attrs)
    _ -> PayForAbilityEffect . (`with` payments) <$> runMessage msg attrs

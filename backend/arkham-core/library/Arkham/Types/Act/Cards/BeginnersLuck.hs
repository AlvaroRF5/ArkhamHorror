{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Act.Cards.BeginnersLuck
  ( BeginnersLuck(..)
  , beginnersLuck
  )
where

import Arkham.Import

import Arkham.Types.Act.Attrs
import Arkham.Types.Card.EncounterCardMatcher
import Arkham.Types.Game.Helpers
import Arkham.Types.ScenarioLogKey
import Arkham.Types.Trait

newtype BeginnersLuck = BeginnersLuck Attrs
  deriving newtype (Show, ToJSON, FromJSON)

beginnersLuck :: BeginnersLuck
beginnersLuck =
  BeginnersLuck $ baseAttrs "02066" "Beginner's Luck" (Act 1 A) Nothing

ability :: Attrs -> Ability
ability attrs = (mkAbility (toSource attrs) 1 (ReactionAbility Free))
  { abilityLimit = GroupLimit PerRound 1
  }

instance ActionRunner env => HasActions env BeginnersLuck where
  getActions iid (WhenRevealToken You _) (BeginnersLuck x) =
    pure [ActivateCardAbilityAction iid (ability x)]
  getActions iid window (BeginnersLuck x) = getActions iid window x

instance
  ( HasQueue env
  , HasList Token env ()
  , HasCount PlayerCount env ()
  , HasCount SpendableClueCount env ()
  , HasSet InvestigatorId env ()
  , HasId LeadInvestigatorId env ()
  , HasSet InScenarioInvestigatorId env ()
  )
  => RunMessage env BeginnersLuck where
  runMessage msg a@(BeginnersLuck attrs@Attrs {..}) = case msg of
    AdvanceAct aid _ | aid == actId && onSide A attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      investigatorIds <- getInvestigatorIds
      requiredClues <- getPlayerCountValue (PerPlayer 4)
      unshiftMessages
        [ SpendClues requiredClues investigatorIds
        , chooseOne leadInvestigatorId [AdvanceAct aid $ toSource attrs]
        ]
      pure $ BeginnersLuck $ attrs & sequenceL .~ Act 1 B
    AdvanceAct aid _ | aid == actId && onSide B attrs -> a <$ unshiftMessages
      [ PlaceLocation "02074"
      , DiscardEncounterUntilFirst
        (toSource attrs)
        (EncounterCardMatchByType (EnemyType, Just Criminal))
      , NextAct aid "02067"
      ]
    RequestedEncounterCard source (Just ec) | isSource attrs source ->
      a <$ unshiftMessage (SpawnEnemyAt (EncounterCard ec) "02074")
    UseCardAbility iid source Nothing 1 | isSource attrs source -> do
      tokensInBag <- getList @Token ()
      a <$ unshiftMessages
        [ FocusTokens tokensInBag
        , chooseOne
          iid
          [ TargetLabel
              (TokenFaceTarget token)
              [ UseCardAbility
                  iid
                  source
                  (Just . TargetMetadata $ TokenFaceTarget token)
                  1
              ]
          | token <- tokensInBag
          ]
        ]
    UseCardAbility iid source (Just (TargetMetadata (TokenFaceTarget token))) 1
      | isSource attrs source -> do
        withQueue $ \queue ->
          ( map
            (\case
              When (RevealToken s i _) -> When (RevealToken s i token)
              RevealToken s i _ -> RevealToken s i token
              After (RevealToken s i _) -> After (RevealToken s i token)
              RequestedTokens source' miid [_] ->
                RequestedTokens source' miid [token]
              RequestedTokens{} -> error "not setup for multiple tokens"
              m -> m
            )
            queue
          , ()
          )
        a <$ unshiftMessages [FocusTokens [token], Remember $ Cheated iid]
    After (GainClues _ _) -> do
      totalClues <- unSpendableClueCount <$> getCount ()
      requiredClues <- getPlayerCountValue (PerPlayer 4)
      a <$ when
        (totalClues >= requiredClues)
        (unshiftMessage $ AdvanceAct actId (toSource attrs))
    _ -> BeginnersLuck <$> runMessage msg attrs

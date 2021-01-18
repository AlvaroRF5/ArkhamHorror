module Arkham.Types.Effect.Effects.ArcaneBarrier
  ( ArcaneBarrier(..)
  , arcaneBarrier
  )
where

import Arkham.Import

import Arkham.Types.Effect.Attrs

newtype ArcaneBarrier = ArcaneBarrier Attrs
  deriving newtype (Show, ToJSON, FromJSON)

arcaneBarrier :: EffectArgs -> ArcaneBarrier
arcaneBarrier = ArcaneBarrier . uncurry4 (baseAttrs "02102")

instance HasModifiersFor env ArcaneBarrier where
  getModifiersFor = noModifiersFor

instance HasQueue env => RunMessage env ArcaneBarrier where
  runMessage msg e@(ArcaneBarrier attrs@Attrs {..}) = case msg of
    CreatedEffect eid _ _ (InvestigatorTarget iid) | eid == effectId ->
      e <$ unshiftMessage
        (BeginSkillTest
          iid
          (toSource attrs)
          (InvestigatorTarget iid)
          Nothing
          SkillWillpower
          4
        )
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        let
          moveMessages = case effectMetadata of
            Just (EffectMessages msgs) -> msgs
            _ -> error "messages must be supplied"
        e <$ unshiftMessages
          [ chooseOne
            iid
            [ Label "Cancel Move" []
            , Label
              "Discard top 5 cards of your deck"
              (DiscardTopOfDeck iid 5 Nothing : moveMessages)
            ]
          , DisableEffect effectId
          ]
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        let
          moveMessages = case effectMetadata of
            Just (EffectMessages msgs) -> msgs
            _ -> error "messages must be supplied"
        case effectSource of
          TreacherySource tid ->
            e <$ unshiftMessages (Discard (TreacheryTarget tid) : moveMessages)
          _ -> error "Has to be a treachery source"
    _ -> ArcaneBarrier <$> runMessage msg attrs

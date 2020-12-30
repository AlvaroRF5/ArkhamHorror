{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Agenda.Cards.InEveryShadow
  ( InEveryShadow(..)
  , inEveryShadow
  )
where

import Arkham.Import

import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Runner

newtype InEveryShadow = InEveryShadow Attrs
  deriving newtype (Show, ToJSON, FromJSON)

inEveryShadow :: InEveryShadow
inEveryShadow =
  InEveryShadow $ baseAttrs "02121" "In Every Shadow" (Agenda 3 A) (Static 7)

instance HasActions env InEveryShadow where
  getActions i window (InEveryShadow x) = getActions i window x

instance HasModifiersFor env InEveryShadow where
  getModifiersFor = noModifiersFor

instance AgendaRunner env => RunMessage env InEveryShadow where
  runMessage msg a@(InEveryShadow attrs@Attrs {..}) = case msg of
    EnemySpawn _ _ eid -> do
      cardCode <- getId @CardCode eid
      when (cardCode == CardCode "02141") $ do
        mShadowSpawnedId <- fmap unStoryTreacheryId <$> getId (CardCode "02142")
        case mShadowSpawnedId of
          Just tid -> unshiftMessage $ PlaceResources (TreacheryTarget tid) 1
          Nothing ->
            unshiftMessage $ AttachStoryTreacheryTo "02142" (EnemyTarget eid)
      pure a
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 3 A -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      unshiftMessage $ Ask leadInvestigatorId (ChooseOne [AdvanceAgenda aid])
      pure
        $ InEveryShadow
        $ attrs
        & (sequenceL .~ Agenda 3 B)
        & (flippedL .~ True)
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 3 B -> do
      iids <- map unInScenarioInvestigatorId <$> getSetList ()
      a <$ unshiftMessages
        (concatMap
          (\iid -> [SufferTrauma iid 1 0, InvestigatorDefeated iid])
          iids
        )
    _ -> InEveryShadow <$> runMessage msg attrs

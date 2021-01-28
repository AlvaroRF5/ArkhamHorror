module Arkham.Types.Agenda.Cards.RestrictedAccess
  ( RestrictedAccess(..)
  , restrictedAccess
  ) where

import Arkham.Import

import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Runner
import Arkham.Types.Card.EncounterCardMatcher

newtype RestrictedAccess = RestrictedAccess Attrs
  deriving newtype (Show, ToJSON, FromJSON)

restrictedAccess :: RestrictedAccess
restrictedAccess = RestrictedAccess
  $ baseAttrs "02119" "Restricted Access" (Agenda 1 A) (Static 5)

instance HasActions env RestrictedAccess where
  getActions i window (RestrictedAccess x) = getActions i window x

instance HasModifiersFor env RestrictedAccess where
  getModifiersFor = noModifiersFor

instance AgendaRunner env => RunMessage env RestrictedAccess where
  runMessage msg a@(RestrictedAccess attrs@Attrs {..}) = case msg of
    EnemySpawn _ _ eid -> do
      cardCode <- getId @CardCode eid
      when (cardCode == CardCode "02141") $ do
        mShadowSpawnedId <- fmap unStoryTreacheryId <$> getId (CardCode "02142")
        case mShadowSpawnedId of
          Just tid -> unshiftMessage $ PlaceResources (TreacheryTarget tid) 1
          Nothing ->
            unshiftMessage $ AttachStoryTreacheryTo "02142" (EnemyTarget eid)
      pure a
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      mHuntingHorrorId <- fmap unStoryEnemyId <$> getId (CardCode "02141")
      a <$ case mHuntingHorrorId of
        Just eid -> unshiftMessages
          [PlaceDoom (EnemyTarget eid) 1, NextAgenda agendaId "02120"]
        Nothing -> unshiftMessage $ FindEncounterCard
          leadInvestigatorId
          (toTarget attrs)
          (EncounterCardMatchByCardCode "02141")
    FoundEnemyInVoid _ target eid | isTarget attrs target -> do
      lid <- fromJustNote "Museum Halls missing"
        <$> getLocationIdWithTitle "Museum Halls"
      a <$ unshiftMessages
        [EnemySpawnFromVoid Nothing lid eid, NextAgenda agendaId "02120"]
    FoundEncounterCard _ target ec | isTarget attrs target -> do
      lid <- fromJustNote "Museum Halls missing"
        <$> getLocationIdWithTitle "Museum Halls"
      a <$ unshiftMessages
        [SpawnEnemyAt (EncounterCard ec) lid, NextAgenda agendaId "02120"]
    _ -> RestrictedAccess <$> runMessage msg attrs

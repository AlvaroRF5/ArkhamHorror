module Arkham.Types.Agenda.Cards.InEveryShadow
  ( InEveryShadow(..)
  , inEveryShadow
  )
where

import Arkham.Prelude

import Arkham.EncounterCard
import qualified Arkham.Treachery.Cards as Treacheries
import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Runner
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.InvestigatorId
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.TreacheryId

newtype InEveryShadow = InEveryShadow AgendaAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

inEveryShadow :: InEveryShadow
inEveryShadow =
  InEveryShadow $ baseAttrs "02121" "In Every Shadow" (Agenda 3 A) (Static 7)

instance HasActions env InEveryShadow where
  getActions i window (InEveryShadow x) = getActions i window x

instance HasModifiersFor env InEveryShadow where
  getModifiersFor = noModifiersFor

instance AgendaRunner env => RunMessage env InEveryShadow where
  runMessage msg a@(InEveryShadow attrs@AgendaAttrs {..}) = case msg of
    EnemySpawn _ _ eid -> do
      cardCode <- getId @CardCode eid
      when (cardCode == CardCode "02141") $ do
        mShadowSpawnedId <- fmap unStoryTreacheryId
          <$> getId (toCardCode Treacheries.shadowSpawned)
        shadowSpawned <- EncounterCard
          <$> genEncounterCard Treacheries.shadowSpawned
        case mShadowSpawnedId of
          Just tid -> push $ PlaceResources (TreacheryTarget tid) 1
          Nothing ->
            push $ AttachStoryTreacheryTo shadowSpawned (EnemyTarget eid)
      pure a
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 3 B -> do
      iids <- map unInScenarioInvestigatorId <$> getSetList ()
      a <$ pushAll
        (concatMap
          (\iid -> [SufferTrauma iid 1 0, InvestigatorDefeated iid])
          iids
        )
    _ -> InEveryShadow <$> runMessage msg attrs

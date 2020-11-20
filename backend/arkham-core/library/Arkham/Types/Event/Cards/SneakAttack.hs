{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event.Cards.SneakAttack where

import Arkham.Import

import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner

newtype SneakAttack = SneakAttack Attrs
  deriving newtype (Show, ToJSON, FromJSON)

sneakAttack :: InvestigatorId -> EventId -> SneakAttack
sneakAttack iid uuid = SneakAttack $ baseAttrs iid uuid "01052"

instance HasModifiersFor env SneakAttack where
  getModifiersFor = noModifiersFor

instance HasActions env SneakAttack where
  getActions i window (SneakAttack attrs) = getActions i window attrs

instance EventRunner env => RunMessage env SneakAttack where
  runMessage msg e@(SneakAttack attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      lid <- getId @LocationId iid
      enemyIds <- map unExhaustedEnemyId <$> getSetList lid
      e <$ unshiftMessages
        ([ EnemyDamage enemyId iid (EventSource eventId) 2
         | enemyId <- enemyIds
         ]
        <> [Discard (EventTarget eventId)]
        )
    _ -> SneakAttack <$> runMessage msg attrs

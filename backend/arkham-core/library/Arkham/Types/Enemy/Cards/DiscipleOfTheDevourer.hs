module Arkham.Types.Enemy.Cards.DiscipleOfTheDevourer where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner

newtype DiscipleOfTheDevourer = DiscipleOfTheDevourer Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

discipleOfTheDevourer :: EnemyId -> DiscipleOfTheDevourer
discipleOfTheDevourer uuid =
  DiscipleOfTheDevourer
    $ baseAttrs uuid "50041"
    $ (healthDamageL .~ 1)
    . (fightL .~ 3)
    . (healthL .~ Static 1)
    . (evadeL .~ 1)

instance HasModifiersFor env DiscipleOfTheDevourer where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env DiscipleOfTheDevourer where
  getActions i window (DiscipleOfTheDevourer attrs) = getActions i window attrs

instance EnemyRunner env => RunMessage env DiscipleOfTheDevourer where
  runMessage msg e@(DiscipleOfTheDevourer attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId -> do
      farthestEmptyLocationIds <- map unFarthestLocationId
        <$> getSetList (iid, EmptyLocation)
      e <$ spawnAtOneOf iid eid farthestEmptyLocationIds
    EnemySpawn (Just iid) _ eid | eid == enemyId -> do
      let
        messages =
          [PlaceDoom (toTarget attrs) 1, InvestigatorPlaceCluesOnLocation iid 1]
      step <- asks $ unAgendaStep . getStep
      if step == 1
        then unshiftMessage (chooseOne iid messages)
        else unshiftMessages messages
      DiscipleOfTheDevourer <$> runMessage msg attrs
    _ -> DiscipleOfTheDevourer <$> runMessage msg attrs

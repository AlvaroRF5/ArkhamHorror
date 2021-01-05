module Arkham.Types.Enemy.Cards.LupineThrall
  ( LupineThrall(..)
  , lupineThrall
  )
where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner

newtype LupineThrall = LupineThrall Attrs
  deriving newtype (Show, ToJSON, FromJSON)

lupineThrall :: EnemyId -> LupineThrall
lupineThrall uuid =
  LupineThrall
    $ baseAttrs uuid "02095"
    $ (healthDamageL .~ 1)
    . (sanityDamageL .~ 1)
    . (fightL .~ 4)
    . (healthL .~ Static 3)
    . (evadeL .~ 4)
    . (preyL .~ LowestSkill SkillAgility)

instance ActionRunner env => HasActions env LupineThrall where
  getActions i window (LupineThrall attrs) = getActions i window attrs

instance HasModifiersFor env LupineThrall where
  getModifiersFor = noModifiersFor

instance EnemyRunner env => RunMessage env LupineThrall where
  runMessage msg e@(LupineThrall attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId -> do
      farthestLocations <- map unFarthestLocationId <$> getSetList iid
      e <$ spawnAtOneOf iid eid farthestLocations
    _ -> LupineThrall <$> runMessage msg attrs

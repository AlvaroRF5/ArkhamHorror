module Arkham.Types.Enemy.Cards.CrazedShoggoth
  ( CrazedShoggoth(..)
  , crazedShoggoth
  ) where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.Enemy.Attrs
import Arkham.Types.EnemyId
import Arkham.Types.GameValue
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Trait

newtype CrazedShoggoth = CrazedShoggoth EnemyAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

crazedShoggoth :: EnemyId -> CrazedShoggoth
crazedShoggoth uuid =
  CrazedShoggoth
    $ baseAttrs uuid "02295"
    $ (healthDamageL .~ 2)
    . (sanityDamageL .~ 2)
    . (fightL .~ 3)
    . (healthL .~ Static 6)
    . (evadeL .~ 4)

deriving newtype instance EnemyAttrsHasActions env => HasActions env CrazedShoggoth

instance HasModifiersFor env CrazedShoggoth where
  getModifiersFor = noModifiersFor

instance
  ( HasSet ClosestLocationId env (LocationId , [Trait])
  , EnemyAttrsRunMessage env
  )
  => RunMessage env CrazedShoggoth where
  runMessage msg e@(CrazedShoggoth attrs) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId attrs -> do
      lid <- getId @LocationId iid
      closestAlteredLocationIds <- map unClosestLocationId
        <$> getSetList (lid, [Altered])
      e <$ spawnAtOneOf iid eid closestAlteredLocationIds
    InvestigatorWhenDefeated source iid | isSource attrs source ->
      e <$ unshiftMessage (InvestigatorKilled iid)
    _ -> CrazedShoggoth <$> runMessage msg attrs

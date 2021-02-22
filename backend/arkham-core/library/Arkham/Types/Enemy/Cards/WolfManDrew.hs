module Arkham.Types.Enemy.Cards.WolfManDrew where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.EnemyId
import Arkham.Types.GameValue
import Arkham.Types.LocationMatcher
import Arkham.Types.Message

newtype WolfManDrew = WolfManDrew EnemyAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wolfManDrew :: EnemyId -> WolfManDrew
wolfManDrew uuid =
  WolfManDrew
    $ baseAttrs uuid "01137"
    $ (healthDamageL .~ 2)
    . (fightL .~ 4)
    . (healthL .~ Static 4)
    . (evadeL .~ 2)
    . (uniqueL .~ True)
    . (spawnAtL ?~ LocationWithTitle "Downtown")

instance HasModifiersFor env WolfManDrew where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env WolfManDrew where
  getActions i window (WolfManDrew attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env WolfManDrew where
  runMessage msg (WolfManDrew attrs) = case msg of
    PerformEnemyAttack _ eid | eid == enemyId attrs ->
      WolfManDrew <$> runMessage msg (attrs & damageL %~ max 0 . subtract 1)
    _ -> WolfManDrew <$> runMessage msg attrs

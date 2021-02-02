module Arkham.Types.Enemy.Cards.RuthTurner where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner

newtype RuthTurner = RuthTurner Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

ruthTurner :: EnemyId -> RuthTurner
ruthTurner uuid =
  RuthTurner
    $ baseAttrs uuid "01141"
    $ (healthDamageL .~ 1)
    . (fightL .~ 2)
    . (healthL .~ Static 4)
    . (evadeL .~ 5)
    . (uniqueL .~ True)

instance HasModifiersFor env RuthTurner where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env RuthTurner where
  getActions i window (RuthTurner attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env RuthTurner where
  runMessage msg e@(RuthTurner attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId ->
      e <$ spawnAt (Just iid) eid (LocationWithTitle "St. Mary's Hospital")
    EnemyEvaded _ eid | eid == enemyId ->
      e <$ unshiftMessage (AddToVictory (EnemyTarget enemyId))
    _ -> RuthTurner <$> runMessage msg attrs

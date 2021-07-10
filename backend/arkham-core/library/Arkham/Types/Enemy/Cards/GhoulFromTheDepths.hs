module Arkham.Types.Enemy.Cards.GhoulFromTheDepths
  ( GhoulFromTheDepths(..)
  , ghoulFromTheDepths
  ) where

import Arkham.Prelude

import qualified Arkham.Enemy.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.LocationMatcher
import Arkham.Types.Message

newtype GhoulFromTheDepths = GhoulFromTheDepths EnemyAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ghoulFromTheDepths :: EnemyCard GhoulFromTheDepths
ghoulFromTheDepths =
  enemy GhoulFromTheDepths Cards.ghoulFromTheDepths (3, Static 4, 2) (1, 1)

instance HasModifiersFor env GhoulFromTheDepths

instance ActionRunner env => HasActions env GhoulFromTheDepths where
  getActions i window (GhoulFromTheDepths attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env GhoulFromTheDepths where
  runMessage msg e@(GhoulFromTheDepths attrs@EnemyAttrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId ->
      e <$ spawnAt (Just iid) enemyId (LocationWithTitle "Bathroom")
    _ -> GhoulFromTheDepths <$> runMessage msg attrs

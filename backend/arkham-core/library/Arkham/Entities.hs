module Arkham.Entities where

import Arkham.Prelude

import Arkham.Act
import Arkham.Agenda
import Arkham.Asset
import Arkham.Classes.Entity
import Arkham.Classes.RunMessage
import Arkham.Effect
import Arkham.Enemy
import Arkham.Event
import Arkham.Investigator
import Arkham.Json
import Arkham.Location
import Arkham.Skill
import Arkham.Treachery

type EntityMap a = HashMap (EntityId a) a

data Entities = Entities
  { entitiesLocations :: EntityMap Location
  , entitiesInvestigators :: EntityMap Investigator
  , entitiesEnemies :: EntityMap Enemy
  , entitiesAssets :: EntityMap Asset
  , entitiesActs :: EntityMap Act
  , entitiesAgendas :: EntityMap Agenda
  , entitiesTreacheries :: EntityMap Treachery
  , entitiesEvents :: EntityMap Event
  , entitiesEffects :: EntityMap Effect
  , entitiesSkills :: EntityMap Skill
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON Entities where
  toJSON = genericToJSON $ aesonOptions $ Just "entities"

instance FromJSON Entities where
  parseJSON = genericParseJSON $ aesonOptions $ Just "entities"

locationsL :: Lens' Entities (EntityMap Location)
locationsL = lens entitiesLocations $ \m x -> m { entitiesLocations = x }

investigatorsL :: Lens' Entities (EntityMap Investigator)
investigatorsL = lens entitiesInvestigators $ \m x -> m { entitiesInvestigators = x }

enemiesL :: Lens' Entities (EntityMap Enemy)
enemiesL = lens entitiesEnemies $ \m x -> m { entitiesEnemies = x }

assetsL :: Lens' Entities (EntityMap Asset)
assetsL = lens entitiesAssets $ \m x -> m { entitiesAssets = x }

actsL :: Lens' Entities (EntityMap Act)
actsL = lens entitiesActs $ \m x -> m { entitiesActs = x }

agendasL :: Lens' Entities (EntityMap Agenda)
agendasL = lens entitiesAgendas $ \m x -> m { entitiesAgendas = x }

treacheriesL :: Lens' Entities (EntityMap Treachery)
treacheriesL = lens entitiesTreacheries $ \m x -> m { entitiesTreacheries = x }

eventsL :: Lens' Entities (EntityMap Event)
eventsL = lens entitiesEvents $ \m x -> m { entitiesEvents = x }

effectsL :: Lens' Entities (EntityMap Effect)
effectsL = lens entitiesEffects $ \m x -> m { entitiesEffects = x }

skillsL :: Lens' Entities (EntityMap Skill)
skillsL = lens entitiesSkills $ \m x -> m { entitiesSkills = x }

defaultEntities :: Entities
defaultEntities = Entities
  { entitiesLocations = mempty
  , entitiesInvestigators = mempty
  , entitiesEnemies = mempty
  , entitiesAssets = mempty
  , entitiesActs = mempty
  , entitiesAgendas = mempty
  , entitiesTreacheries = mempty
  , entitiesEvents = mempty
  , entitiesEffects = mempty
  , entitiesSkills = mempty
  }

instance RunMessage Entities where
  runMessage msg entities =
    traverseOf (actsL . traverse) (runMessage msg) entities
      >>= traverseOf (agendasL . traverse) (runMessage msg)
      >>= traverseOf (treacheriesL . traverse) (runMessage msg)
      >>= traverseOf (eventsL . traverse) (runMessage msg)
      >>= traverseOf (locationsL . traverse) (runMessage msg)
      >>= traverseOf (enemiesL . traverse) (runMessage msg)
      >>= traverseOf (effectsL . traverse) (runMessage msg)
      >>= traverseOf (assetsL . traverse) (runMessage msg)
      >>= traverseOf (skillsL . traverse) (runMessage msg)
      >>= traverseOf (investigatorsL . traverse) (runMessage msg)

instance Monoid Entities where
  mempty = defaultEntities

instance Semigroup Entities where
  a <> b = Entities
    { entitiesLocations = entitiesLocations a <> entitiesLocations b
    , entitiesInvestigators = entitiesInvestigators a <> entitiesInvestigators b
    , entitiesEnemies = entitiesEnemies a <> entitiesEnemies b
    , entitiesAssets = entitiesAssets a <> entitiesAssets b
    , entitiesActs = entitiesActs a <> entitiesActs b
    , entitiesAgendas = entitiesAgendas a <> entitiesAgendas b
    , entitiesTreacheries = entitiesTreacheries a <> entitiesTreacheries b
    , entitiesEvents = entitiesEvents a <> entitiesEvents b
    , entitiesEffects = entitiesEffects a <> entitiesEffects b
    , entitiesSkills = entitiesSkills a <> entitiesSkills b
    }

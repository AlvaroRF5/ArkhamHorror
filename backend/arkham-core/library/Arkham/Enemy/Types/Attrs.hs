module Arkham.Enemy.Types.Attrs where

import Arkham.Prelude

import Arkham.Card
import Arkham.GameValue
import Arkham.Id
import Arkham.Json
import Arkham.Matcher
import Arkham.Modifier ( Modifier )
import Arkham.Placement
import Arkham.Source
import Arkham.Strategy
import Arkham.Token

data EnemyAttrs = EnemyAttrs
  { enemyId :: EnemyId
  , enemyCardCode :: CardCode
  , enemyPlacement :: Placement
  , enemyFight :: Int
  , enemyHealth :: GameValue
  , enemyEvade :: Maybe Int
  , enemyDamage :: Int
  , enemyHealthDamage :: Int
  , enemySanityDamage :: Int
  , enemyPrey :: PreyMatcher
  , enemyModifiers :: HashMap Source [Modifier]
  , enemyExhausted :: Bool
  , enemyDoom :: Int
  , enemyClues :: Int
  , enemyResources :: Int
  , enemySpawnAt :: Maybe LocationMatcher
  , enemySurgeIfUnabledToSpawn :: Bool
  , enemyAsSelfLocation :: Maybe Text
  , enemyMovedFromHunterKeyword :: Bool
  , enemyDamageStrategy :: DamageStrategy
  , enemyBearer :: Maybe InvestigatorId
  , enemySealedTokens :: [Token]
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON EnemyAttrs where
  toJSON = genericToJSON $ aesonOptions $ Just "enemy"
  toEncoding = genericToEncoding $ aesonOptions $ Just "enemy"

instance FromJSON EnemyAttrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "enemy"

instance HasCardCode EnemyAttrs where
  toCardCode = enemyCardCode

enemyReady :: EnemyAttrs -> Bool
enemyReady = not . enemyExhausted

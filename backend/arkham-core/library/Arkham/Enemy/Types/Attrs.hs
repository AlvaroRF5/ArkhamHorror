module Arkham.Enemy.Types.Attrs where

import Arkham.Prelude

import Arkham.Card
import Arkham.ChaosToken
import Arkham.DamageEffect
import Arkham.GameValue
import Arkham.Id
import Arkham.Json
import Arkham.Key
import Arkham.Matcher
import Arkham.Modifier (Modifier)
import Arkham.Placement
import Arkham.Source
import Arkham.Spawn
import Arkham.Strategy
import Arkham.Token

data EnemyAttrs = EnemyAttrs
  { enemyId :: EnemyId
  , enemyCardId :: CardId
  , enemyCardCode :: CardCode
  , enemyOriginalCardCode :: CardCode
  , enemyPlacement :: Placement
  , enemyFight :: Int
  , enemyHealth :: GameValue
  , enemyEvade :: Maybe Int
  , enemyAssignedDamage :: Map Source DamageAssignment
  , enemyHealthDamage :: Int
  , enemySanityDamage :: Int
  , enemyPrey :: PreyMatcher
  , enemyModifiers :: Map Source [Modifier]
  , enemyExhausted :: Bool
  , enemyTokens :: Tokens
  , enemySpawnAt :: Maybe SpawnAt
  , enemySurgeIfUnableToSpawn :: Bool
  , enemyAsSelfLocation :: Maybe Text
  , enemyMovedFromHunterKeyword :: Bool
  , enemyDamageStrategy :: DamageStrategy
  , enemyBearer :: Maybe InvestigatorId
  , enemySealedChaosTokens :: [ChaosToken]
  , enemyKeys :: Set ArkhamKey
  , enemySpawnedBy :: Maybe InvestigatorId
  }
  deriving stock (Show, Eq, Generic)

enemyDamage :: EnemyAttrs -> Int
enemyDamage = countTokens Damage . enemyTokens

enemyClues :: EnemyAttrs -> Int
enemyClues = countTokens Clue . enemyTokens

enemyDoom :: EnemyAttrs -> Int
enemyDoom = countTokens Doom . enemyTokens

enemyResources :: EnemyAttrs -> Int
enemyResources = countTokens Resource . enemyTokens

instance ToJSON EnemyAttrs where
  toJSON = genericToJSON $ aesonOptions $ Just "enemy"
  toEncoding = genericToEncoding $ aesonOptions $ Just "enemy"

instance FromJSON EnemyAttrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "enemy"

instance Be EnemyAttrs EnemyMatcher where
  be = EnemyWithId . enemyId

instance HasCardCode EnemyAttrs where
  toCardCode = enemyCardCode

enemyReady :: EnemyAttrs -> Bool
enemyReady = not . enemyExhausted

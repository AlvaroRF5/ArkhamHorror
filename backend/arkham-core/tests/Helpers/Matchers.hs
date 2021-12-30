module Helpers.Matchers where

import Arkham.Prelude

import Arkham.Agenda
import Arkham.Asset
import Arkham.AssetId
import Arkham.Card
import Arkham.Card.EncounterCard
import Arkham.Card.PlayerCard
import Arkham.Classes
import Arkham.Enemy
import Arkham.EnemyId
import Arkham.Event
import Arkham.Game
import Arkham.Investigator
import Arkham.Investigator.Attrs qualified as Investigator
import Arkham.Location
import Arkham.Query
import Arkham.Target
import Arkham.Treachery
import Arkham.TreacheryId
import Control.Lens
import Data.List qualified as L
import Data.Maybe (fromJust)

getTestGame :: (MonadIO m, MonadReader env m, HasGameRef env) => m Game
getTestGame = readIORef =<< view gameRefL

isInDiscardOf
  :: (ToPlayerCard entity, HasGameRef env, MonadIO m, MonadReader env m)
  => Investigator
  -> entity
  -> m Bool
isInDiscardOf investigator entity = do
  game <- getTestGame
  let
    discard' = game ^?! investigatorsL . ix (toId investigator) . to discardOf
  pure $ pcId card `elem` map pcId discard'
  where card = asPlayerCard entity

class ToPlayerCard a where
  asPlayerCard :: a -> PlayerCard

class ToEncounterCard a where
  asEncounterCard :: a -> EncounterCard

instance ToPlayerCard PlayerCard where
  asPlayerCard = id

instance ToPlayerCard Event where
  asPlayerCard event = lookupPlayerCard (toCardDef event) (toCardId event)

instance ToPlayerCard Treachery where
  asPlayerCard treachery =
    lookupPlayerCard (toCardDef treachery) (toCardId treachery)

class (Entity a, TargetEntity a) => TestEntity a where
  updated :: (MonadReader env m, HasGameRef env, MonadIO m) => a -> m a

instance TestEntity Agenda where
  updated a = fromJust . preview (agendasL . ix (toId a)) <$> getTestGame

instance TestEntity Treachery where
  updated t = fromJust . preview (treacheriesL . ix (toId t)) <$> getTestGame

instance TestEntity Asset where
  updated a = fromJust . preview (assetsL . ix (toId a)) <$> getTestGame

instance TestEntity Location where
  updated l = fromJust . preview (locationsL . ix (toId l)) <$> getTestGame

instance TestEntity Event where
  updated e = fromJust . preview (eventsL . ix (toId e)) <$> getTestGame

instance TestEntity Enemy where
  updated e = fromJust . preview (enemiesL . ix (toId e)) <$> getTestGame

instance TestEntity Investigator where
  updated i = fromJust . preview (investigatorsL . ix (toId i)) <$> getTestGame

isAttachedTo
  :: (TestEntity a, TestEntity b, MonadReader env m, HasGameRef env, MonadIO m)
  => a
  -> b
  -> m Bool
isAttachedTo x y = case toTarget x of
  LocationTarget locId -> case toTarget y of
    EventTarget eventId -> do
      game <- getTestGame
      pure
        $ eventId
        `member` (game ^. locationsL . ix locId . to (`getSet` game))
    _ -> pure False
  _ -> pure False

instance ToEncounterCard Enemy where
  asEncounterCard enemy =
    lookupEncounterCard (toCardDef enemy) (toCardId enemy)

isInEncounterDiscard
  :: (ToEncounterCard entity, HasGameRef env, MonadIO m, MonadReader env m)
  => entity
  -> m Bool
isInEncounterDiscard entity = do
  game <- getTestGame
  pure $ card `elem` (game ^. discardL)
  where card = asEncounterCard entity

updatedResourceCount
  :: (HasGameRef env, MonadIO m, MonadReader env m) => Investigator -> m Int
updatedResourceCount investigator = do
  game <- getTestGame
  pure $ game ^?! investigatorsL . ix (toId investigator) . to
    (Investigator.investigatorResources . toAttrs)

evadedBy
  :: (MonadReader env m, HasGameRef env, MonadIO m)
  => Investigator
  -> Enemy
  -> m Bool
evadedBy _investigator enemy = do
  game <- getTestGame
  let enemy' = game ^?! enemiesL . ix (toId enemy)
  pure $ not (isEngaged enemy') && isExhausted enemy'

getRemainingActions
  :: (HasGameRef env, MonadReader env m, MonadIO m) => Investigator -> m Int
getRemainingActions investigator = do
  game <- getTestGame
  let investigator' = game ^?! investigatorsL . ix (toId investigator)
  pure $ actionsRemaining investigator'

hasDamage :: (HasDamage a) => (Int, Int) -> a -> Bool
hasDamage n a = getDamage a == n

hasTrauma :: (HasTrauma a) => (Int, Int) -> a -> Bool
hasTrauma n a = getTrauma a == n

getDoom
  :: ( TargetEntity a
     , HasGameRef env
     , HasGameLogger env
     , HasQueue env
     , HasStdGen env
     , MonadReader env m
     , MonadIO m
     )
  => a
  -> m Int
getDoom a = case toTarget a of
  AgendaTarget aid -> toGameEnv >>= runReaderT (unDoomCount <$> getCount aid)
  _ -> error "Not implemented"

handIs :: [Card] -> Investigator -> Bool
handIs cards i = flip handMatches i $ \hand ->
  null (foldr (flip (L.\\) . pure) hand cards) && length cards == length hand

handMatches :: ([Card] -> Bool) -> Investigator -> Bool
handMatches f i = f (handOf i)

deckMatches :: ([PlayerCard] -> Bool) -> Investigator -> Bool
deckMatches f i = f (deckOf i)

hasEnemy :: (MonadReader env m) => Enemy -> Location -> m Bool
hasEnemy e l = (toId e `member`) <$> getSet @EnemyId l

hasCardInPlay :: (MonadReader env m) => Card -> Investigator -> m Bool
hasCardInPlay c i = case c of
  PlayerCard pc -> case cdCardType (toCardDef pc) of
    AssetType -> (AssetId (pcId pc) `member`) <$> getSet i
    _ -> error "not implemented"
  _ -> error "not implemented"

hasTreacheryWithMatchingCardCode
  :: (HasSet TreacheryId env a, HasGameRef env, MonadIO m, MonadReader env m)
  => Card
  -> a
  -> m Bool
hasTreacheryWithMatchingCardCode c a = do
  game <- getTestGame
  maybe
    (pure False)
    (\treachery -> (toId treachery `member`) <$> getSet a)
    (mtreachery game)
 where
  mtreachery g =
    find ((== toCardCode c) . toCardCode) $ toList (g ^. treacheriesL)

hasClueCount :: HasCount ClueCount () a => Int -> a -> Bool
hasClueCount n a = n == unClueCount (getCount a ())

hasUses :: (HasCount UsesCount () a) => Int -> a -> Bool
hasUses n a = n == unUsesCount (getCount a ())

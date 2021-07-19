module Arkham.Scenarios.CarnevaleOfHorrors.Helpers where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.Id

-- | An across location will be 4 locations away
getAcrossLocation
  :: ( MonadReader env m
     , HasSet LocationId env ()
     , HasSet ConnectedLocationId env LocationId
     )
  => LocationId
  -> m LocationId
getAcrossLocation lid = do
  clockwiseMap <- getClockwiseMap
  pure $ foldl'
    (\lid' _ -> withMissingError $ lookup lid' clockwiseMap)
    lid
    range
 where
  withMissingError = fromJustNote "Could not traverse connected locations"
  range :: [Int]
  range = [1 .. 4]

getCounterClockwiseLocation
  :: ( MonadReader env m
     , HasSet LocationId env ()
     , HasSet ConnectedLocationId env LocationId
     )
  => LocationId
  -> m LocationId
getCounterClockwiseLocation lid = do
  counterClockwiseMap <- getCounterClockwiseMap
  case lookup lid counterClockwiseMap of
    Just x -> pure x
    Nothing -> error "must be connected"

getCounterClockwiseLocations
  :: ( MonadReader env m
     , HasSet LocationId env ()
     , HasSet ConnectedLocationId env LocationId
     )
  => LocationId
  -> m [LocationId]
getCounterClockwiseLocations end = do
  counterClockwiseMap <- getCounterClockwiseMap
  pure $ buildList (lookup end counterClockwiseMap) counterClockwiseMap
 where
  buildList Nothing _ = []
  buildList (Just current) _ | current == end = [end]
  buildList (Just current) counterClockwiseMap =
    current : buildList (lookup current counterClockwiseMap) counterClockwiseMap

getClockwiseMap
  :: ( MonadReader env m
     , HasSet LocationId env ()
     , HasSet ConnectedLocationId env LocationId
     )
  => m (HashMap LocationId LocationId)
getClockwiseMap = do
  lids <- getSetList @LocationId ()
  mapFromList
    . concat
    <$> traverse
          (\lid -> map ((lid, ) . unConnectedLocationId) <$> getSetList lid)
          lids

getCounterClockwiseMap
  :: ( MonadReader env m
     , HasSet LocationId env ()
     , HasSet ConnectedLocationId env LocationId
     )
  => m (HashMap LocationId LocationId)
getCounterClockwiseMap = do
  lids <- getSetList @LocationId ()
  mapFromList
    . concat
    <$> traverse
          (\lid -> map ((, lid) . unConnectedLocationId) <$> getSetList lid)
          lids

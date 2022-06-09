module Arkham.Scenarios.APhantomOfTruth.Helpers
  ( module Arkham.Scenarios.APhantomOfTruth.Helpers
  , module X
  ) where

import Arkham.Prelude

import Arkham.Campaigns.ThePathToCarcosa.Helpers as X
import Arkham.Classes
import Arkham.Cost
import Arkham.Distance
import Arkham.Game.Helpers
import Arkham.Investigator.Attrs (Field (.. ))
import Arkham.Enemy.Attrs (Field (.. ))
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id
import Arkham.Matcher hiding ( MoveAction )
import Arkham.Message
import Arkham.Projection

getTheOrganist :: GameT EnemyId
getTheOrganist = selectJust $ EnemyWithTitle "The Organist"

investigatorsNearestToTheOrganist :: GameT (Distance, [InvestigatorId])
investigatorsNearestToTheOrganist = do
  theOrganist <- getTheOrganist
  investigatorsNearestToEnemy theOrganist

investigatorsNearestToEnemy :: EnemyId -> GameT (Distance, [InvestigatorId])
investigatorsNearestToEnemy eid = do
  enemyLocation <- fieldF
    EnemyLocation
    (fromJustNote "must be at a location")
    eid
  investigatorIdWithLocationId <-
    fmap catMaybes
    . traverse (\i -> fmap (i, ) <$> field InvestigatorLocation i)
    =<< selectList UneliminatedInvestigator

  mappings <- catMaybes <$> traverse
    (\(i, l) -> fmap (i, ) <$> getDistance enemyLocation l)
    investigatorIdWithLocationId

  let
    minDistance :: Int =
      fromJustNote "error" . minimumMay $ map (unDistance . snd) mappings
  pure . (Distance minDistance, ) . hashNub . map fst $ filter
    ((== minDistance) . unDistance . snd)
    mappings

moveOrganistAwayFromNearestInvestigator :: GameT Message
moveOrganistAwayFromNearestInvestigator = do
  organist <- getTheOrganist
  leadInvestigatorId <- getLeadInvestigatorId
  (minDistance, iids) <- investigatorsNearestToTheOrganist
  everywhere <- selectList Anywhere

  lids <- setFromList . concat <$> for
    iids
    (\iid -> do
      currentLocation <- fieldF InvestigatorLocation (fromJustNote "must be at a location") iid
      rs <- traverse (traverseToSnd (fmap (fromMaybe (Distance 0)) . getDistance currentLocation)) everywhere
      pure $ map fst $ filter ((> minDistance) . snd) rs
    )
  withNoInvestigators <- select LocationWithoutInvestigators
  let
    forced = lids `intersect` withNoInvestigators
    targets = toList $ if null forced then lids else forced
  pure $ chooseOrRunOne
    leadInvestigatorId
    [ targetLabel lid [EnemyMove organist lid] | lid <- targets ]

disengageEachEnemyAndMoveToConnectingLocation :: GameT [Message]
disengageEachEnemyAndMoveToConnectingLocation = do
  leadInvestigatorId <- getLeadInvestigatorId
  iids <- getInvestigatorIds
  enemyPairs <- traverse
    (traverseToSnd (selectList . EnemyIsEngagedWith . InvestigatorWithId))
    iids
  locationPairs <- traverse
    (traverseToSnd
      (selectList
      . AccessibleFrom
      . LocationWithInvestigator
      . InvestigatorWithId
      )
    )
    iids
  pure
    $ [ DisengageEnemy iid enemy
      | (iid, enemies) <- enemyPairs
      , enemy <- enemies
      ]
    <> [ chooseOneAtATime
           leadInvestigatorId
           [ targetLabel
               iid
               [ chooseOne
                   iid
                   [ targetLabel lid [MoveAction iid lid Free False]
                   | lid <- locations
                   ]
               ]
           | (iid, locations) <- locationPairs
           ]
       ]

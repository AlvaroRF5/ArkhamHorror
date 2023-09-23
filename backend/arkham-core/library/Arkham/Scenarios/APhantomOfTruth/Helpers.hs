module Arkham.Scenarios.APhantomOfTruth.Helpers (
  module Arkham.Scenarios.APhantomOfTruth.Helpers,
  module X,
) where

import Arkham.Prelude

import Arkham.Campaigns.ThePathToCarcosa.Helpers as X
import Arkham.Classes
import Arkham.Distance
import Arkham.Enemy.Types (Field (..))
import Arkham.Game.Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id
import Arkham.Investigator.Types (Field (..))
import Arkham.Matcher
import Arkham.Message
import Arkham.Movement
import Arkham.Projection
import Arkham.Source

getTheOrganist :: HasGame m => m EnemyId
getTheOrganist = selectJust $ EnemyWithTitle "The Organist"

investigatorsNearestToTheOrganist
  :: HasGame m => m (Distance, [InvestigatorId])
investigatorsNearestToTheOrganist = do
  theOrganist <- getTheOrganist
  investigatorsNearestToEnemy theOrganist

investigatorsNearestToEnemy
  :: HasGame m => EnemyId -> m (Distance, [InvestigatorId])
investigatorsNearestToEnemy eid = do
  enemyLocation <-
    fieldMap
      EnemyLocation
      (fromJustNote "must be at a location")
      eid
  investigatorIdWithLocationId <-
    fmap catMaybes
      . traverse (\i -> fmap (i,) <$> field InvestigatorLocation i)
      =<< selectList UneliminatedInvestigator

  mappings <-
    catMaybes
      <$> traverse
        (\(i, l) -> fmap (i,) <$> getDistance enemyLocation l)
        investigatorIdWithLocationId

  let
    minDistance :: Int =
      fromJustNote "error" . minimumMay $ map (unDistance . snd) mappings
  pure
    . (Distance minDistance,)
    . nub
    . map fst
    $ filter
      ((== minDistance) . unDistance . snd)
      mappings

moveOrganistAwayFromNearestInvestigator :: HasGame m => m Message
moveOrganistAwayFromNearestInvestigator = do
  organist <- getTheOrganist
  leadInvestigatorId <- getLeadInvestigatorId
  (minDistance, iids) <- investigatorsNearestToTheOrganist
  everywhere <- selectList Anywhere

  lids <-
    setFromList
      . concat
      <$> for
        iids
        ( \iid -> do
            currentLocation <-
              fieldMap
                InvestigatorLocation
                (fromJustNote "must be at a location")
                iid
            rs <-
              forToSnd
                everywhere
                (fmap (fromMaybe (Distance 0)) . getDistance currentLocation)
            pure $ map fst $ filter ((> minDistance) . snd) rs
        )
  withNoInvestigators <- select LocationWithoutInvestigators
  let
    forced = lids `intersect` withNoInvestigators
    targets = toList $ if null forced then lids else forced
  pure
    $ chooseOrRunOne
      leadInvestigatorId
      [targetLabel lid [EnemyMove organist lid] | lid <- targets]

disengageEachEnemyAndMoveToConnectingLocation
  :: (HasGame m, Sourceable source) => source -> m [Message]
disengageEachEnemyAndMoveToConnectingLocation source = do
  leadInvestigatorId <- getLeadInvestigatorId
  iids <- getInvestigatorIds
  enemyPairs <-
    forToSnd
      iids
      (selectList . EnemyIsEngagedWith . InvestigatorWithId)
  locationPairs <-
    forToSnd
      iids
      ( selectList . AccessibleFrom . LocationWithInvestigator . InvestigatorWithId
      )
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
                [ targetLabel lid [Move $ move source iid lid]
                | lid <- locations
                ]
            ]
          | (iid, locations) <- locationPairs
          ]
       ]

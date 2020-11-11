{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Cards.SlimeCoveredDhole
  ( SlimeCoveredDhole(..)
  , slimeCoveredDhole
  )
where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Helpers
import Arkham.Types.Enemy.Runner
import Arkham.Types.Trait

newtype SlimeCoveredDhole = SlimeCoveredDhole Attrs
  deriving newtype (Show, ToJSON, FromJSON)

slimeCoveredDhole :: EnemyId -> SlimeCoveredDhole
slimeCoveredDhole uuid =
  SlimeCoveredDhole
    $ baseAttrs uuid "81031"
    $ (healthDamage .~ 1)
    . (sanityDamage .~ 1)
    . (fight .~ 2)
    . (health .~ Static 3)
    . (evade .~ 3)
    . (prey .~ LowestRemainingHealth)

instance HasModifiersFor env SlimeCoveredDhole where
  getModifiersFor = noModifiersFor

instance HasModifiers env SlimeCoveredDhole where
  getModifiers _ (SlimeCoveredDhole Attrs {..}) =
    pure . concat . toList $ enemyModifiers

instance ActionRunner env => HasActions env SlimeCoveredDhole where
  getActions i window (SlimeCoveredDhole attrs) = getActions i window attrs

bayouLocations
  :: (MonadReader env m, HasSet LocationId [Trait] env)
  => m (HashSet LocationId)
bayouLocations = asks $ getSet [Bayou]

nonBayouLocations
  :: ( MonadReader env m
     , HasSet LocationId () env
     , HasSet LocationId [Trait] env
     )
  => m (HashSet LocationId)
nonBayouLocations = difference <$> getLocationSet <*> bayouLocations

instance (EnemyRunner env) => RunMessage env SlimeCoveredDhole where
  runMessage msg e@(SlimeCoveredDhole attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy _ _ eid | eid == enemyId -> do
      leadInvestigatorId <- getLeadInvestigatorId
      spawnLocations <- setToList <$> nonBayouLocations
      e <$ spawnAtOneOf leadInvestigatorId enemyId spawnLocations
    EnemyMove eid _ lid | eid == enemyId -> do
      investigatorIds <- asks $ setToList . getSet @InvestigatorId lid
      e <$ unshiftMessages
        [ InvestigatorAssignDamage iid (toSource attrs) 0 1
        | iid <- investigatorIds
        ]
    _ -> SlimeCoveredDhole <$> runMessage msg attrs

{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.OnTheProwl
  ( OnTheProwl(..)
  , onTheProwl
  )
where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner
import Arkham.Types.Trait

newtype OnTheProwl = OnTheProwl Attrs
  deriving newtype (Show, ToJSON, FromJSON)

onTheProwl :: TreacheryId -> a -> OnTheProwl
onTheProwl uuid _ = OnTheProwl $ baseAttrs uuid "81034"

instance HasModifiersFor env OnTheProwl where
  getModifiersFor = noModifiersFor

instance HasActions env OnTheProwl where
  getActions i window (OnTheProwl attrs) = getActions i window attrs

bayouLocations
  :: (MonadReader env m, HasSet LocationId env [Trait])
  => m (HashSet LocationId)
bayouLocations = getSet [Bayou]

nonBayouLocations
  :: ( MonadReader env m
     , HasSet LocationId env ()
     , HasSet LocationId env [Trait]
     )
  => m (HashSet LocationId)
nonBayouLocations = difference <$> getLocationSet <*> bayouLocations

instance TreacheryRunner env => RunMessage env OnTheProwl where
  runMessage msg (OnTheProwl attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      mrougarou <- fmap unStoryEnemyId <$> getId (CardCode "81028")
      case mrougarou of
        Nothing -> unshiftMessage (Discard (TreacheryTarget treacheryId))
        Just eid -> do
          locationIds <- setToList <$> nonBayouLocations
          locationsWithClueCounts <- for locationIds
            $ \lid -> (lid, ) . unClueCount <$> getCount lid
          let
            sortedLocationsWithClueCounts = sortOn snd locationsWithClueCounts
          case sortedLocationsWithClueCounts of
            [] -> unshiftMessage (Discard (TreacheryTarget treacheryId))
            ((_, c) : _) ->
              let
                (matches, _) =
                  span ((== c) . snd) sortedLocationsWithClueCounts
              in
                case matches of
                  [(x, _)] -> unshiftMessages
                    [ MoveUntil x (EnemyTarget eid)
                    , Discard (TreacheryTarget treacheryId)
                    ]
                  xs -> unshiftMessages
                    [ chooseOne
                      iid
                      [ MoveUntil x (EnemyTarget eid) | (x, _) <- xs ]
                    , Discard (TreacheryTarget treacheryId)
                    ]
      OnTheProwl <$> runMessage msg (attrs & resolved .~ True)
    _ -> OnTheProwl <$> runMessage msg attrs

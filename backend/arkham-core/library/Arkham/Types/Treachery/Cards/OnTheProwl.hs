module Arkham.Types.Treachery.Cards.OnTheProwl
  ( OnTheProwl(..)
  , onTheProwl
  ) where

import Arkham.Prelude

import Arkham.Scenarios.CurseOfTheRougarou.Helpers
import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Query
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype OnTheProwl = OnTheProwl TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env, HasAbilities env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

onTheProwl :: TreacheryCard OnTheProwl
onTheProwl = treachery OnTheProwl Cards.onTheProwl

instance TreacheryRunner env => RunMessage env OnTheProwl where
  runMessage msg t@(OnTheProwl attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      mrougarou <- fmap unStoryEnemyId <$> getId (CardCode "81028")
      t <$ case mrougarou of
        Nothing -> push (Discard (TreacheryTarget treacheryId))
        Just eid -> do
          locationIds <- setToList <$> nonBayouLocations
          locationsWithClueCounts <- for locationIds
            $ \lid -> (lid, ) . unClueCount <$> getCount lid
          let
            sortedLocationsWithClueCounts = sortOn snd locationsWithClueCounts
          case sortedLocationsWithClueCounts of
            [] -> push (Discard (TreacheryTarget treacheryId))
            ((_, c) : _) ->
              let
                (matches, _) =
                  span ((== c) . snd) sortedLocationsWithClueCounts
              in
                case matches of
                  [(x, _)] ->
                    pushAll
                      [ MoveUntil x (EnemyTarget eid)
                      , Discard (TreacheryTarget treacheryId)
                      ]
                  xs -> pushAll
                    [ chooseOne
                      iid
                      [ MoveUntil x (EnemyTarget eid) | (x, _) <- xs ]
                    , Discard (TreacheryTarget treacheryId)
                    ]
    _ -> OnTheProwl <$> runMessage msg attrs

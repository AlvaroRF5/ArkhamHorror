module Arkham.Types.Location.Cards.AudubonPark where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (audubonPark)
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message

newtype AudubonPark = AudubonPark LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

audubonPark :: LocationCard AudubonPark
audubonPark = location AudubonPark 
  Cards.audubonPark
  3
  (PerPlayer 1)
  Squiggle
  [Triangle, Squiggle]

instance HasModifiersFor env AudubonPark where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env AudubonPark where
  getActions i window (AudubonPark attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env AudubonPark where
  runMessage msg l@(AudubonPark attrs@LocationAttrs {..}) = case msg of
    EnemyEvaded iid eid | eid `member` locationEnemies ->
      l <$ unshiftMessage (RandomDiscard iid)
    _ -> AudubonPark <$> runMessage msg attrs

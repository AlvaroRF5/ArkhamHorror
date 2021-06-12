module Arkham.Types.Location.Cards.RitualSite where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Query
import Arkham.Types.Trait

newtype RitualSite = RitualSite LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ritualSite :: LocationId -> RitualSite
ritualSite = RitualSite . baseAttrs
  "01156"
  "Ritual Site"
  EncounterSet.TheDevourerBelow
  3
  (PerPlayer 2)
  Plus
  [Squiggle]
  [Cave]

instance HasModifiersFor env RitualSite where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env RitualSite where
  getActions i window (RitualSite attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env RitualSite where
  runMessage msg (RitualSite attrs) = case msg of
    EndRound -> do
      playerCount <- getCount ()
      RitualSite <$> runMessage
        msg
        (attrs & cluesL .~ fromGameValue
          (PerPlayer 2)
          (unPlayerCount playerCount)
        )
    _ -> RitualSite <$> runMessage msg attrs

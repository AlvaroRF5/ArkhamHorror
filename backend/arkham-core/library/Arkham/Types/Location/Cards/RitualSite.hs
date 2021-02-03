module Arkham.Types.Location.Cards.RitualSite where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype RitualSite = RitualSite LocationAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

ritualSite :: RitualSite
ritualSite = RitualSite $ baseAttrs
  "01156"
  (Name "Ritual Site" Nothing)
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
      playerCount <- unPlayerCount <$> getCount ()
      RitualSite <$> runMessage
        msg
        (attrs & cluesL .~ fromGameValue (PerPlayer 2) playerCount)
    _ -> RitualSite <$> runMessage msg attrs

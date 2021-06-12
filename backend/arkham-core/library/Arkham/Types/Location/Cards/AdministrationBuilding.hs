module Arkham.Types.Location.Cards.AdministrationBuilding where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationMatcher
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Trait

newtype AdministrationBuilding = AdministrationBuilding LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

administrationBuilding :: LocationId -> AdministrationBuilding
administrationBuilding = AdministrationBuilding . baseAttrs
  "02053"
  "Administration Building"
  EncounterSet.ExtracurricularActivity
  4
  (PerPlayer 1)
  Circle
  [Plus, T]
  [Miskatonic]

instance HasModifiersFor env AdministrationBuilding where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env AdministrationBuilding where
  getActions i window (AdministrationBuilding attrs) =
    getActions i window attrs

instance (LocationRunner env) => RunMessage env AdministrationBuilding where
  runMessage msg l@(AdministrationBuilding attrs) = case msg of
    RevealLocation _ lid | lid == locationId attrs -> do
      unshiftMessage
        $ PlaceLocationMatching (LocationWithTitle "Faculty Offices")
      AdministrationBuilding <$> runMessage msg attrs
    EndTurn iid | iid `elem` locationInvestigators attrs ->
      l <$ unshiftMessage (DiscardTopOfDeck iid 1 Nothing)
    _ -> AdministrationBuilding <$> runMessage msg attrs

module Arkham.Types.Location.Cards.RitualGrounds where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Name
import Arkham.Types.Trait

newtype RitualGrounds = RitualGrounds LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ritualGrounds :: LocationId -> RitualGrounds
ritualGrounds lid = RitualGrounds $ base { locationVictory = Just 1 }
 where
  base = baseAttrs
    lid
    "81017"
    (Name "Ritual Grounds" Nothing)
    EncounterSet.CurseOfTheRougarou
    2
    (PerPlayer 1)
    Equals
    [Hourglass, Equals]
    [Unhallowed]

instance HasModifiersFor env RitualGrounds where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env RitualGrounds where
  getActions i window (RitualGrounds attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env RitualGrounds where
  runMessage msg l@(RitualGrounds attrs@LocationAttrs {..}) = case msg of
    EndTurn iid | iid `elem` locationInvestigators -> l <$ unshiftMessages
      [ DrawCards iid 1 False
      , InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 1
      ]
    _ -> RitualGrounds <$> runMessage msg attrs

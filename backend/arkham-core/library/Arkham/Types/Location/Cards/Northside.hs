module Arkham.Types.Location.Cards.Northside
  ( Northside(..)
  , northside
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Name
import Arkham.Types.Trait
import Arkham.Types.Window

newtype Northside = Northside LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

northside :: LocationId -> Northside
northside lid = Northside $ base { locationVictory = Just 1 }
 where
  base = baseAttrs
    lid
    "01134"
    (Name "Northside" Nothing)
    EncounterSet.TheMidnightMasks
    3
    (PerPlayer 2)
    T
    [Diamond, Triangle]
    [Arkham]

instance HasModifiersFor env Northside where
  getModifiersFor = noModifiersFor

ability :: LocationAttrs -> Ability
ability attrs = base { abilityLimit = GroupLimit PerGame 1 }
 where
  base = mkAbility
    (toSource attrs)
    1
    (ActionAbility Nothing $ Costs [ActionCost 1, ResourceCost 5])

instance ActionRunner env => HasActions env Northside where
  getActions iid NonFast (Northside attrs@LocationAttrs {..})
    | locationRevealed = withBaseActions iid NonFast attrs $ pure
      [ ActivateCardAbilityAction iid (ability attrs)
      | iid `member` locationInvestigators
      ]
  getActions iid window (Northside attrs) = getActions iid window attrs

instance (LocationRunner env) => RunMessage env Northside where
  runMessage msg l@(Northside attrs@LocationAttrs {..}) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ unshiftMessage (GainClues iid 2)
    _ -> Northside <$> runMessage msg attrs

module Arkham.Types.Location.Cards.Schoolhouse_212
  ( schoolhouse_212
  , Schoolhouse_212(..)
  ) where

import Arkham.Prelude

import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Modifier
import Arkham.Types.Name
import Arkham.Types.Target
import Arkham.Types.Trait

newtype Schoolhouse_212 = Schoolhouse_212 LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

schoolhouse_212 :: LocationId -> Schoolhouse_212
schoolhouse_212 lid = Schoolhouse_212 $ baseAttrs
  lid
  "02212"
  (Name "Schoolhouse" Nothing)
  EncounterSet.BloodOnTheAltar
  4
  (Static 1)
  Moon
  [Plus, Squiggle, Circle]
  [Dunwich]

instance HasModifiersFor env Schoolhouse_212 where
  getModifiersFor _ (InvestigatorTarget iid) (Schoolhouse_212 attrs) =
    pure $ toModifiers
      attrs
      [ CannotCommitCards | iid `member` locationInvestigators attrs ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env Schoolhouse_212 where
  getActions = withDrawCardUnderneathAction

instance LocationRunner env => RunMessage env Schoolhouse_212 where
  runMessage msg (Schoolhouse_212 attrs) =
    Schoolhouse_212 <$> runMessage msg attrs

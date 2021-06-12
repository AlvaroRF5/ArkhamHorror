module Arkham.Types.Location.Cards.FauborgMarigny
  ( FauborgMarigny(..)
  , fauborgMarigny
  )
where

import Arkham.Prelude

import Arkham.Types.Card
import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Modifier
import Arkham.Types.Target
import Arkham.Types.Trait

newtype FauborgMarigny = FauborgMarigny LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fauborgMarigny :: LocationId -> FauborgMarigny
fauborgMarigny = FauborgMarigny . baseAttrs
  "81012"
  "Faurborg Marigny"
  EncounterSet.CurseOfTheRougarou
  4
  (Static 0)
  Squiggle
  [Triangle, Squiggle]
  [Riverside]

instance HasModifiersFor env FauborgMarigny where
  getModifiersFor _ (InvestigatorTarget iid) (FauborgMarigny attrs) =
    pure $ toModifiers
      attrs
      [ ReduceCostOfCardType AssetType 1
      | iid `member` locationInvestigators attrs
      ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env FauborgMarigny where
  getActions = withResignAction

instance (LocationRunner env) => RunMessage env FauborgMarigny where
  runMessage msg (FauborgMarigny attrs) =
    FauborgMarigny <$> runMessage msg attrs

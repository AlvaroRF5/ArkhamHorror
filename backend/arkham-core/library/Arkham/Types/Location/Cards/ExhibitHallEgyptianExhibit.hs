module Arkham.Types.Location.Cards.ExhibitHallEgyptianExhibit
  ( exhibitHallEgyptianExhibit
  , ExhibitHallEgyptianExhibit(..)
  ) where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype ExhibitHallEgyptianExhibit = ExhibitHallEgyptianExhibit Attrs
  deriving newtype (Show, ToJSON, FromJSON)

exhibitHallEgyptianExhibit :: ExhibitHallEgyptianExhibit
exhibitHallEgyptianExhibit = ExhibitHallEgyptianExhibit
  $ base { locationVictory = Just 1 }
 where
  base = baseAttrs
    "02135"
    (Name "ExhibitHall" $ Just "Egyptian Exhibit")
    EncounterSet.TheMiskatonicMuseum
    3
    (PerPlayer 2)
    Moon
    [Square, T]
    [Miskatonic, Exhibit]

instance HasModifiersFor env ExhibitHallEgyptianExhibit where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ExhibitHallEgyptianExhibit where
  getActions iid window (ExhibitHallEgyptianExhibit attrs) =
    getActions iid window attrs

instance LocationRunner env => RunMessage env ExhibitHallEgyptianExhibit where
  runMessage msg l@(ExhibitHallEgyptianExhibit attrs) = case msg of
    After (FailedSkillTest iid (Just Action.Investigate) _ target _)
      | isTarget attrs target -> l
      <$ unshiftMessage (LoseActions iid (toSource attrs) 1)
    _ -> ExhibitHallEgyptianExhibit <$> runMessage msg attrs

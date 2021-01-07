module Arkham.Types.Location.Cards.ExhibitHallNatureExhibit
  ( exhibitHallNatureExhibit
  , ExhibitHallNatureExhibit(..)
  ) where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype ExhibitHallNatureExhibit = ExhibitHallNatureExhibit Attrs
  deriving newtype (Show, ToJSON, FromJSON)

exhibitHallNatureExhibit :: ExhibitHallNatureExhibit
exhibitHallNatureExhibit = ExhibitHallNatureExhibit
  $ base { locationVictory = Just 1 }
 where
  base = baseAttrs
    "02134"
    (Name "Exhibit Hall" $ Just "Nature Exhibit")
    EncounterSet.TheMiskatonicMuseum
    4
    (PerPlayer 1)
    Hourglass
    [Square, Squiggle]
    [Miskatonic, Exhibit]

instance HasModifiersFor env ExhibitHallNatureExhibit where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ExhibitHallNatureExhibit where
  getActions iid window (ExhibitHallNatureExhibit attrs) =
    getActions iid window attrs

instance LocationRunner env => RunMessage env ExhibitHallNatureExhibit where
  runMessage msg l@(ExhibitHallNatureExhibit attrs) = case msg of
    After (FailedSkillTest iid (Just Action.Investigate) _ target _)
      | isTarget attrs target -> l
      <$ unshiftMessages [RandomDiscard iid, RandomDiscard iid]
    _ -> ExhibitHallNatureExhibit <$> runMessage msg attrs

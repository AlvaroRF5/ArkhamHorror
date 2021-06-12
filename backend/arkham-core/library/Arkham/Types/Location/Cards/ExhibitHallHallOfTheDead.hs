module Arkham.Types.Location.Cards.ExhibitHallHallOfTheDead
  ( exhibitHallHallOfTheDead
  , ExhibitHallHallOfTheDead(..)
  )
where

import Arkham.Prelude

import qualified Arkham.Types.Action as Action
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

newtype ExhibitHallHallOfTheDead = ExhibitHallHallOfTheDead LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

exhibitHallHallOfTheDead :: LocationId -> ExhibitHallHallOfTheDead
exhibitHallHallOfTheDead =
  ExhibitHallHallOfTheDead . (victoryL ?~ 1) . baseAttrs
    "02136"
    ("Exhibit Hall" `subtitled` "Hall of the Dead")
    EncounterSet.TheMiskatonicMuseum
    3
    (PerPlayer 2)
    Squiggle
    [Square, Hourglass]
    [Miskatonic, Exhibit]

instance HasModifiersFor env ExhibitHallHallOfTheDead where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ExhibitHallHallOfTheDead where
  getActions iid window (ExhibitHallHallOfTheDead attrs) =
    getActions iid window attrs

instance LocationRunner env => RunMessage env ExhibitHallHallOfTheDead where
  runMessage msg l@(ExhibitHallHallOfTheDead attrs) = case msg of
    After (FailedSkillTest iid (Just Action.Investigate) _ target _ _)
      | isTarget attrs target -> l <$ unshiftMessage
        (InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 1)
    _ -> ExhibitHallHallOfTheDead <$> runMessage msg attrs

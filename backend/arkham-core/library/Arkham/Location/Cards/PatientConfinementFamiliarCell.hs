module Arkham.Location.Cards.PatientConfinementFamiliarCell
  ( patientConfinementFamiliarCell
  , PatientConfinementFamiliarCell(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Message
import Arkham.Query
import Arkham.ScenarioLogKey
import Arkham.SkillType
import Arkham.Target

newtype PatientConfinementFamiliarCell = PatientConfinementFamiliarCell LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

patientConfinementFamiliarCell :: LocationCard PatientConfinementFamiliarCell
patientConfinementFamiliarCell = locationWith
  PatientConfinementFamiliarCell
  Cards.patientConfinementFamiliarCell
  2
  (Static 1)
  Moon
  [Squiggle]
  (costToEnterUnrevealedL .~ Costs [ActionCost 1, ClueCost 1])

instance HasAbilities PatientConfinementFamiliarCell where
  getAbilities (PatientConfinementFamiliarCell attrs) = withBaseAbilities
    attrs
    [ restrictedAbility attrs 1 Here $ ActionAbility Nothing (ActionCost 1)
    | locationRevealed attrs
    ]

instance RunMessage PatientConfinementFamiliarCell where
  runMessage msg l@(PatientConfinementFamiliarCell attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      horror <- unHorrorCount <$> getCount iid
      push $ BeginSkillTest
        iid
        source
        (toTarget attrs)
        Nothing
        SkillWillpower
        horror
      pure l
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> l <$ push (Remember RecalledTheWayOut)
    _ -> PatientConfinementFamiliarCell <$> runMessage msg attrs

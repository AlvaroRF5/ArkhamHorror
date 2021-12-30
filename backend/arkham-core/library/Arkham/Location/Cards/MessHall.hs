module Arkham.Location.Cards.MessHall
  ( messHall
  , MessHall(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Classes
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Attrs
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing

newtype MessHall = MessHall LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

messHall :: LocationCard MessHall
messHall =
  location MessHall Cards.messHall 2 (PerPlayer 2) Triangle [Circle, Square]

instance HasAbilities MessHall where
  getAbilities (MessHall attrs) = withBaseAbilities
    attrs
    [ restrictedAbility attrs 1 Here
      $ ForcedAbility
      $ SkillTestResult Timing.After You (WhileInvestigating YourLocation)
      $ SuccessResult AnyValue
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage env MessHall where
  runMessage msg l@(MessHall attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ push (ChooseAndDiscardCard iid)
    _ -> MessHall <$> runMessage msg attrs

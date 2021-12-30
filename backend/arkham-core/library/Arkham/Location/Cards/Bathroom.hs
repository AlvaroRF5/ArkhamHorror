module Arkham.Location.Cards.Bathroom where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (bathroom)
import Arkham.Classes
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Attrs
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing
import Arkham.Token

newtype Bathroom = Bathroom LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

bathroom :: LocationCard Bathroom
bathroom = location Bathroom Cards.bathroom 1 (PerPlayer 1) Star [T]

instance HasAbilities Bathroom where
  getAbilities (Bathroom attrs) =
    withBaseAbilities attrs $
      [ restrictedAbility
          attrs
          1
          (DuringSkillTest $ WhileInvestigating $ LocationWithId $ toId attrs)
        $ ForcedAbility
        $ RevealChaosToken Timing.After You
        $ TokenMatchesAny
        $ map TokenFaceIs [Skull, Cultist, Tablet, AutoFail]
      | locationRevealed attrs
      ]

instance LocationRunner env => RunMessage env Bathroom where
  runMessage msg l@(Bathroom attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ pushAll [SetActions iid source 0, ChooseEndTurn iid]
    _ -> Bathroom <$> runMessage msg attrs

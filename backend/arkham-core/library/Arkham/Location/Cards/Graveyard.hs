module Arkham.Location.Cards.Graveyard where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (graveyard)
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype Graveyard = Graveyard LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

graveyard :: LocationCard Graveyard
graveyard =
  location Graveyard Cards.graveyard 1 (PerPlayer 2) Hourglass [Circle]

instance HasAbilities Graveyard where
  getAbilities (Graveyard x) = withBaseAbilities x $
    [ mkAbility x 1
        $ ForcedAbility (Enters Timing.After Anyone $ LocationWithId (toId x))
    ]

instance RunMessage Graveyard where
  runMessage msg l@(Graveyard attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> l <$ push
      (BeginSkillTest
        iid
        source
        (InvestigatorTarget iid)
        Nothing
        SkillWillpower
        3
      )
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        rivertownId <- getJustLocationIdByName "Rivertown"
        l <$ push
          (chooseOne
            iid
            [ Label
              "Take 2 horror"
              [InvestigatorAssignDamage iid source DamageAny 0 2]
            , Label
              "Move to Rivertown"
              [MoveTo (toSource attrs) iid rivertownId]
            ]
          )
    _ -> Graveyard <$> runMessage msg attrs

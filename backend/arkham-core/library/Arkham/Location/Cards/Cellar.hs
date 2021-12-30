module Arkham.Location.Cards.Cellar where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (cellar)
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing

newtype Cellar = Cellar LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cellar :: LocationCard Cellar
cellar = location Cellar Cards.cellar 4 (PerPlayer 2) Plus [Square]

instance HasAbilities Cellar where
  getAbilities (Cellar a) = withBaseAbilities a $
    [ mkAbility a 1
      $ ForcedAbility
      $ Enters Timing.After You
      $ LocationWithId
      $ toId a
    ]

instance LocationRunner env => RunMessage env Cellar where
  runMessage msg a@(Cellar attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (InvestigatorAssignDamage iid (toSource attrs) DamageAny 1 0)
    _ -> Cellar <$> runMessage msg attrs

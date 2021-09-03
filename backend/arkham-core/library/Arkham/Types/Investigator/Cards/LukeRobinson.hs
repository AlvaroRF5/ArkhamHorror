module Arkham.Types.Investigator.Cards.LukeRobinson where

import Arkham.Prelude

import Arkham.Types.Investigator.Attrs

newtype LukeRobinson = LukeRobinson InvestigatorAttrs
  deriving anyclass (HasAbilities, HasModifiersFor env)
  deriving newtype (Show, ToJSON, FromJSON, Entity)

lukeRobinson :: LukeRobinson
lukeRobinson = LukeRobinson $ baseAttrs
  "06004"
  "Luke Robinson"
  Mystic
  Stats
    { health = 5
    , sanity = 9
    , willpower = 4
    , intellect = 3
    , combat = 2
    , agility = 3
    }
  [Dreamer, Drifter, Wayfarer]

instance (InvestigatorRunner env) => RunMessage env LukeRobinson where
  runMessage msg (LukeRobinson attrs) = LukeRobinson <$> runMessage msg attrs

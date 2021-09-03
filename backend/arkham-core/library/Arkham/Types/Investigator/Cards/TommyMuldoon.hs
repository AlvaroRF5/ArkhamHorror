module Arkham.Types.Investigator.Cards.TommyMuldoon where

import Arkham.Prelude

import Arkham.Types.Investigator.Attrs

newtype TommyMuldoon = TommyMuldoon InvestigatorAttrs
  deriving anyclass (HasAbilities, HasModifiersFor env)
  deriving newtype (Show, ToJSON, FromJSON, Entity)

tommyMuldoon :: TommyMuldoon
tommyMuldoon = TommyMuldoon $ baseAttrs
  "06001"
  "Tommy Muldoon"
  Guardian
  Stats
    { health = 8
    , sanity = 6
    , willpower = 3
    , intellect = 3
    , combat = 4
    , agility = 2
    }
  [Police, Warden]

instance (InvestigatorRunner env) => RunMessage env TommyMuldoon where
  runMessage msg (TommyMuldoon attrs) = TommyMuldoon <$> runMessage msg attrs

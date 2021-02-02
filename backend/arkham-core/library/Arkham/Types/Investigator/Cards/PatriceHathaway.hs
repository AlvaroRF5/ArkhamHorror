module Arkham.Types.Investigator.Cards.PatriceHathaway where

import Arkham.Import

import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Stats
import Arkham.Types.Trait

newtype PatriceHathaway = PatriceHathaway Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

instance HasModifiersFor env PatriceHathaway where
  getModifiersFor source target (PatriceHathaway attrs) =
    getModifiersFor source target attrs

patriceHathaway :: PatriceHathaway
patriceHathaway = PatriceHathaway $ baseAttrs
  "06005"
  "Patrice Hathaway"
  Survivor
  Stats
    { health = 7
    , sanity = 7
    , willpower = 4
    , intellect = 2
    , combat = 2
    , agility = 2
    }
  [Performer, Cursed]

instance ActionRunner env => HasActions env PatriceHathaway where
  getActions i window (PatriceHathaway attrs) = getActions i window attrs

instance (InvestigatorRunner env) => RunMessage env PatriceHathaway where
  runMessage msg (PatriceHathaway attrs) =
    PatriceHathaway <$> runMessage msg attrs

module Arkham.Types.Investigator.Cards.JacquelineFine where

import Arkham.Prelude

import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Stats
import Arkham.Types.Trait

newtype JacquelineFine = JacquelineFine InvestigatorAttrs
  deriving anyclass (HasAbilities env)
  deriving newtype (Show, ToJSON, FromJSON, Entity)

instance HasModifiersFor env JacquelineFine where
  getModifiersFor source target (JacquelineFine attrs) =
    getModifiersFor source target attrs

jacquelineFine :: JacquelineFine
jacquelineFine = JacquelineFine $ baseAttrs
  "60401"
  "Jacqueline Fine"
  Mystic
  Stats
    { health = 6
    , sanity = 9
    , willpower = 5
    , intellect = 3
    , combat = 2
    , agility = 2
    }
  [Clairvoyant]

instance (InvestigatorRunner env) => RunMessage env JacquelineFine where
  runMessage msg (JacquelineFine attrs) =
    JacquelineFine <$> runMessage msg attrs

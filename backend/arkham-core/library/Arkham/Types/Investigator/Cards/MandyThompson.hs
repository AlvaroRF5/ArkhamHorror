module Arkham.Types.Investigator.Cards.MandyThompson where

import Arkham.Prelude

import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Stats
import Arkham.Types.Trait

newtype MandyThompson = MandyThompson InvestigatorAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

instance HasModifiersFor env MandyThompson where
  getModifiersFor source target (MandyThompson attrs) =
    getModifiersFor source target attrs

mandyThompson :: MandyThompson
mandyThompson = MandyThompson $ baseAttrs
  "06002"
  "Mandy Thompson"
  Seeker
  Stats
    { health = 6
    , sanity = 8
    , willpower = 3
    , intellect = 5
    , combat = 1
    , agility = 3
    }
  [Assistant, Scholar]

instance InvestigatorRunner env => HasAbilities env MandyThompson where
  getAbilities i window (MandyThompson attrs) = getAbilities i window attrs

instance (InvestigatorRunner env) => RunMessage env MandyThompson where
  runMessage msg (MandyThompson attrs) = MandyThompson <$> runMessage msg attrs

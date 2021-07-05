module Arkham.Types.Investigator.Cards.MarieLambeau where

import Arkham.Prelude

import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Stats
import Arkham.Types.Trait

newtype MarieLambeau = MarieLambeau InvestigatorAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

instance HasModifiersFor env MarieLambeau where
  getModifiersFor source target (MarieLambeau attrs) =
    getModifiersFor source target attrs

marieLambeau :: MarieLambeau
marieLambeau = MarieLambeau $ baseAttrs
  "05006"
  "Marie Lambeau"
  Mystic
  Stats
    { health = 6
    , sanity = 8
    , willpower = 4
    , intellect = 4
    , combat = 1
    , agility = 3
    }
  [Performer, Sorcerer]

instance InvestigatorRunner env => HasActions env MarieLambeau where
  getActions i window (MarieLambeau attrs) = getActions i window attrs

instance (InvestigatorRunner env) => RunMessage env MarieLambeau where
  runMessage msg (MarieLambeau attrs) = MarieLambeau <$> runMessage msg attrs

module Arkham.Types.Investigator.Cards.WinifredHabbamock where

import Arkham.Prelude

import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Stats
import Arkham.Types.Trait

newtype WinifredHabbamock = WinifredHabbamock InvestigatorAttrs
  deriving anyclass (HasAbilities, HasModifiersFor env)
  deriving newtype (Show, ToJSON, FromJSON, Entity)

winifredHabbamock :: WinifredHabbamock
winifredHabbamock = WinifredHabbamock $ baseAttrs
  "60301"
  "Winifred Habbamock"
  Rogue
  Stats
    { health = 8
    , sanity = 7
    , willpower = 1
    , intellect = 3
    , combat = 3
    , agility = 5
    }
  [Criminal]

instance (InvestigatorRunner env) => RunMessage env WinifredHabbamock where
  runMessage msg (WinifredHabbamock attrs) =
    WinifredHabbamock <$> runMessage msg attrs

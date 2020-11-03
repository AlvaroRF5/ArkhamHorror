{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Investigator.Cards.SilasMarsh where

import Arkham.Import

import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Stats
import Arkham.Types.Trait

newtype SilasMarsh = SilasMarsh Attrs
  deriving newtype (Show, ToJSON, FromJSON)

instance HasModifiersFor env SilasMarsh where
  getModifiersFor source target (SilasMarsh attrs) =
    getModifiersFor source target attrs

silasMarsh :: SilasMarsh
silasMarsh = SilasMarsh $ baseAttrs
  "98013"
  "Silas Marsh"
  Survivor
  Stats
    { health = 9
    , sanity = 5
    , willpower = 2
    , intellect = 2
    , combat = 4
    , agility = 4
    }
  [Drifter]

instance ActionRunner env => HasActions env SilasMarsh where
  getActions i window (SilasMarsh attrs) = getActions i window attrs

instance (InvestigatorRunner env) => RunMessage env SilasMarsh where
  runMessage msg (SilasMarsh attrs) = SilasMarsh <$> runMessage msg attrs

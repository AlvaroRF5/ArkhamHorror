{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Location.Cards.Study where

import Arkham.Json
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import ClassyPrelude

newtype Study = Study Attrs
  deriving newtype (Show, ToJSON, FromJSON)

study :: Study
study = Study $ baseAttrs "01111" "Study" 2 (PerPlayer 2) Circle []

instance (IsInvestigator investigator) => HasActions env investigator Study where
  getActions i (Study attrs) = getActions i attrs

instance (LocationRunner env) => RunMessage env Study where
  runMessage msg (Study attrs) = Study <$> runMessage msg attrs

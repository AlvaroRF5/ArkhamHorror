module Arkham.Location.Cards.ChapelAttic_176
  ( chapelAttic_176
  , ChapelAttic_176(..)
  )
where

import Arkham.Prelude

import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner

newtype ChapelAttic_176 = ChapelAttic_176 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

chapelAttic_176 :: LocationCard ChapelAttic_176
chapelAttic_176 = location ChapelAttic_176 Cards.chapelAttic_176 8 (Static 0)

instance HasAbilities ChapelAttic_176 where
  getAbilities (ChapelAttic_176 attrs) =
    getAbilities attrs
    -- withRevealedAbilities attrs []

instance RunMessage ChapelAttic_176 where
  runMessage msg (ChapelAttic_176 attrs) =
    ChapelAttic_176 <$> runMessage msg attrs

module Arkham.Types.Location.Cards.DimensionalGap
  ( dimensionalGap
  , DimensionalGap(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (dimensionalGap)
import Arkham.Types.Ability
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Window

newtype DimensionalGap = DimensionalGap LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dimensionalGap :: LocationCard DimensionalGap
dimensionalGap = locationWith
  DimensionalGap
  Cards.dimensionalGap
  3
  (PerPlayer 1)
  NoSymbol
  []
  ((revealedSymbolL .~ T)
  . (revealedConnectedSymbolsL .~ setFromList [Square, Moon])
  )

instance HasModifiersFor env DimensionalGap

forcedAbility :: LocationAttrs -> Ability
forcedAbility a = mkAbility (toSource a) 1 ForcedAbility

instance ActionRunner env => HasActions env DimensionalGap where
  getActions iid (AfterRevealLocation You) (DimensionalGap attrs) =
    pure [locationAbility iid (forcedAbility attrs)]
  getActions iid window (DimensionalGap attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env DimensionalGap where
  runMessage msg l@(DimensionalGap attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      l
        <$ push
             (DiscardEncounterUntilFirst source
             $ CardMatchByType (EnemyType, mempty)
             )
    RequestedEncounterCard source (Just ec) | isSource attrs source ->
      l <$ push (SpawnEnemyAt (EncounterCard ec) (toId attrs))
    _ -> DimensionalGap <$> runMessage msg attrs

module Arkham.Location.Cards.HistoricalSocietyPeabodysOffice
  ( historicalSocietyPeabodysOffice
  , HistoricalSocietyPeabodysOffice(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Assets
import Arkham.Location.Cards qualified as Cards
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher hiding (RevealLocation)
import Arkham.Message
import Arkham.Modifier
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype HistoricalSocietyPeabodysOffice = HistoricalSocietyPeabodysOffice LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

historicalSocietyPeabodysOffice :: LocationCard HistoricalSocietyPeabodysOffice
historicalSocietyPeabodysOffice = locationWithRevealedSideConnections
  HistoricalSocietyPeabodysOffice
  Cards.historicalSocietyPeabodysOffice
  4
  (PerPlayer 2)
  NoSymbol
  [Star]
  Moon
  [Star]

instance Query AssetMatcher env => HasModifiersFor env HistoricalSocietyPeabodysOffice where
  getModifiersFor _ (LocationTarget lid) (HistoricalSocietyPeabodysOffice attrs)
    | toId attrs == lid = do
      modifierIsActive <- notNull <$> select
        (assetIs Assets.mrPeabody
        <> AssetControlledBy (InvestigatorAt $ LocationWithId lid)
        )
      pure $ toModifiers attrs [ ShroudModifier (-2) | modifierIsActive ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities HistoricalSocietyPeabodysOffice where
  getAbilities (HistoricalSocietyPeabodysOffice attrs) = withBaseAbilities
    attrs
    [ mkAbility attrs 1 $ ForcedAbility $ EnemySpawns
        Timing.When
        (LocationWithId $ toId attrs)
        AnyEnemy
    | not (locationRevealed attrs)
    ]


instance LocationRunner env => RunMessage env HistoricalSocietyPeabodysOffice where
  runMessage msg l@(HistoricalSocietyPeabodysOffice attrs) = case msg of
    UseCardAbility _ source _ 1 _
      | isSource attrs source && not (locationRevealed attrs) -> l
      <$ push (RevealLocation Nothing $ toId attrs)
    _ -> HistoricalSocietyPeabodysOffice <$> runMessage msg attrs

module Arkham.Types.Act.Cards.AscendingTheHillV3
  ( AscendingTheHillV3(..)
  , ascendingTheHillV3
  ) where

import Arkham.Prelude

import qualified Arkham.Enemy.Cards as Enemies
import Arkham.Types.Act.Attrs
import Arkham.Types.Act.Runner
import Arkham.Types.Card
import Arkham.Types.Card.EncounterCard
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.GameValue
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Target
import Arkham.Types.Trait

newtype AscendingTheHillV3 = AscendingTheHillV3 ActAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ascendingTheHillV3 :: AscendingTheHillV3
ascendingTheHillV3 = AscendingTheHillV3
  $ baseAttrs "02280" "Ascending the Hill (v. III)" (Act 2 A) Nothing

instance HasSet Trait env LocationId => HasModifiersFor env AscendingTheHillV3 where
  getModifiersFor _ (LocationTarget lid) (AscendingTheHillV3 attrs) = do
    traits <- getSet lid
    pure $ toModifiers attrs [ CannotPlaceClues | Altered `notMember` traits ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env AscendingTheHillV3 where
  getActions i window (AscendingTheHillV3 x) = getActions i window x

instance (HasName env LocationId, ActRunner env) => RunMessage env AscendingTheHillV3 where
  runMessage msg a@(AscendingTheHillV3 attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ | aid == actId && onSide B attrs -> do
      sentinelPeak <- fromJustNote "must exist"
        <$> getLocationIdWithTitle "Sentinel Peak"
      sethBishop <- EncounterCard <$> genEncounterCard Enemies.sethBishop
      a <$ pushAll
        [ CreateEnemyAt sethBishop sentinelPeak (Just $ toTarget attrs)
        , NextAct actId "02281"
        ]
    CreatedEnemyAt eid _ target | isTarget attrs target -> do
      damage <- getPlayerCountValue (PerPlayer 1)
      a <$ push (EnemySetDamage eid (toSource attrs) damage)
    WhenEnterLocation _ lid -> do
      name <- getName lid
      a <$ when
        (name == "Sentinel Peak")
        (push $ AdvanceAct actId (toSource attrs))
    _ -> AscendingTheHillV3 <$> runMessage msg attrs

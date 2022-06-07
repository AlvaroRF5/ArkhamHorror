module Arkham.Enemy.Cards.CorpseTaker
  ( CorpseTaker(..)
  , corpseTaker
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import qualified Arkham.Enemy.Cards as Cards
import Arkham.Enemy.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Phase
import qualified Arkham.Timing as Timing

newtype CorpseTaker = CorpseTaker EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

corpseTaker :: EnemyCard CorpseTaker
corpseTaker = enemyWith
  CorpseTaker
  Cards.corpseTaker
  (4, Static 3, 3)
  (1, 2)
  (spawnAtL ?~ FarthestLocationFromYou EmptyLocation)

instance HasAbilities CorpseTaker where
  getAbilities (CorpseTaker x) = withBaseAbilities
    x
    [ mkAbility x 1 $ ForcedAbility $ PhaseEnds Timing.When $ PhaseIs
      MythosPhase
    , mkAbility x 2 $ ForcedAbility $ PhaseEnds Timing.When $ PhaseIs EnemyPhase
    ]

instance RunMessage CorpseTaker where
  runMessage msg e@(CorpseTaker attrs@EnemyAttrs {..}) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      e <$ pure (PlaceDoom (toTarget attrs) 1)
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      case enemyLocation of
        Nothing -> pure e
        Just loc -> do
          mRivertown <- selectOne (LocationWithTitle "Rivertown")
          mMainPath <- selectOne (LocationWithTitle "Main Path")
          let
            locationId = fromJustNote
              "one of these has to exist"
              (mRivertown <|> mMainPath)
          if loc == locationId
            then do
              pushAll (replicate enemyDoom PlaceDoomOnAgenda)
              pure $ CorpseTaker $ attrs & doomL .~ 0
            else do
              leadInvestigatorId <- getLeadInvestigatorId
              closestLocationIds <- selectList $ ClosestPathLocation loc locationId
              case closestLocationIds of
                [lid] -> e <$ push (EnemyMove enemyId lid)
                lids ->
                  e
                    <$ push
                         (chooseOne
                           leadInvestigatorId
                           [ EnemyMove enemyId lid | lid <- lids ]
                         )
    _ -> CorpseTaker <$> runMessage msg attrs

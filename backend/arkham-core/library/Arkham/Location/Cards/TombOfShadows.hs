module Arkham.Location.Cards.TombOfShadows
  ( tombOfShadows
  , TombOfShadows(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message hiding ( RevealLocation )
import Arkham.Modifier
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype TombOfShadows = TombOfShadows LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

tombOfShadows :: LocationCard TombOfShadows
tombOfShadows = locationWith
  TombOfShadows
  Cards.tombOfShadows
  4
  (PerPlayer 2)
  NoSymbol
  []
  ((connectsToL .~ adjacentLocations)
  . (costToEnterUnrevealedL
    .~ Costs [ActionCost 1, GroupClueCost (PerPlayer 1) YourLocation]
    )
  )

instance Query EnemyMatcher env => HasModifiersFor env TombOfShadows where
  getModifiersFor _ (EnemyTarget eid) (TombOfShadows attrs) = do
    active <- member eid <$> select
      (enemyIs Enemies.theManInThePallidMask
      <> EnemyAt (LocationWithId $ toId attrs)
      )
    -- preventing the man in the pallid mask from being defeate is handled by
    -- the man in the pallid mask
    pure $ toModifiers attrs [ HealthModifier 1 | active ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities TombOfShadows where
  getAbilities (TombOfShadows attrs) = withBaseAbilities
    attrs
    [ mkAbility attrs 1 $ ForcedAbility $ RevealLocation
        Timing.When
        Anyone
        (LocationWithId $ toId attrs)
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage TombOfShadows where
  runMessage msg l@(TombOfShadows attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      actIds <- getSetList ()
      pushAll (map (\aid -> AdvanceAct aid source AdvancedWithOther) actIds)
      pure l
    _ -> TombOfShadows <$> runMessage msg attrs

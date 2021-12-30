module Arkham.Act.Cards.TheChamberOfTheBeast
  ( TheChamberOfTheBeast(..)
  , theChamberOfTheBeast
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards qualified as Cards
import Arkham.Asset.Cards qualified as Cards
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Act.Attrs
import Arkham.Act.Helpers
import Arkham.Act.Runner
import Arkham.Classes
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Message hiding (EnemyDefeated)
import Arkham.Resolution
import Arkham.Timing qualified as Timing

newtype TheChamberOfTheBeast = TheChamberOfTheBeast ActAttrs
  deriving anyclass (IsAct, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theChamberOfTheBeast :: ActCard TheChamberOfTheBeast
theChamberOfTheBeast =
  act (2, A) TheChamberOfTheBeast Cards.theChamberOfTheBeast Nothing

instance HasAbilities TheChamberOfTheBeast where
  getAbilities (TheChamberOfTheBeast x) =
    [ mkAbility x 1
    $ Objective
    $ ForcedAbility
    $ EnemyDefeated Timing.After Anyone
    $ enemyIs Cards.silasBishop
    , restrictedAbility
      x
      2
      (LocationExists
      $ LocationWithTitle "The Hidden Chamber"
      <> LocationWithoutClues
      )
    $ Objective
    $ ForcedAbility AnyWindow
    ]

instance ActRunner env => RunMessage env TheChamberOfTheBeast where
  runMessage msg a@(TheChamberOfTheBeast attrs) = case msg of
    AdvanceAct aid _ | aid == toId attrs && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      resolution <- maybe 3 (const 2)
        <$> selectOne (assetIs Cards.theNecronomiconOlausWormiusTranslation)
      a <$ push
        (chooseOne
          leadInvestigatorId
          [ Label
              ("Resolution " <> tshow resolution)
              [ScenarioResolution $ Resolution resolution]
          ]
        )
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (ScenarioResolution $ Resolution 1)
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      a <$ push (AdvanceAct (toId attrs) source)
    _ -> TheChamberOfTheBeast <$> runMessage msg attrs

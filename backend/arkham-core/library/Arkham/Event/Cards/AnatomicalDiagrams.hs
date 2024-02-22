module Arkham.Event.Cards.AnatomicalDiagrams (
  anatomicalDiagrams,
  AnatomicalDiagrams (..),
) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Game.Helpers
import Arkham.Matcher

newtype AnatomicalDiagrams = AnatomicalDiagrams EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

anatomicalDiagrams :: EventCard AnatomicalDiagrams
anatomicalDiagrams = event AnatomicalDiagrams Cards.anatomicalDiagrams

instance RunMessage AnatomicalDiagrams where
  runMessage msg e@(AnatomicalDiagrams attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      enemies <-
        selectMap EnemyTarget $ EnemyAt YourLocation <> NonEliteEnemy
      player <- getPlayer iid
      e
        <$ pushAll
          [ chooseOrRunOne
              player
              [ TargetLabel
                enemy
                [ CreateWindowModifierEffect
                    EffectTurnWindow
                    ( EffectModifiers
                        $ toModifiers attrs [EnemyFight (-2), EnemyEvade (-2)]
                    )
                    (toSource attrs)
                    enemy
                ]
              | enemy <- enemies
              ]
          ]
    _ -> AnatomicalDiagrams <$> runMessage msg attrs

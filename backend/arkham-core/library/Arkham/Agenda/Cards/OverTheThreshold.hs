module Arkham.Agenda.Cards.OverTheThreshold
  ( OverTheThreshold(..)
  , overTheThreshold
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Runner
import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Enemy.Types ( Field (EnemyHealthDamage) )
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Source
import Arkham.Timing qualified as Timing
import Arkham.Trait ( Trait (Humanoid, SilverTwilight, Spectral), toTraits )

newtype OverTheThreshold = OverTheThreshold AgendaAttrs
  deriving anyclass IsAgenda
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

instance HasModifiersFor OverTheThreshold where
  getModifiersFor (EnemyTarget eid) (OverTheThreshold a) = do
    isSilverTwilight <- eid <=~> EnemyWithTrait SilverTwilight
    pure $ toModifiers
      a
      [ CountsAsInvestigatorForHunterEnemies | isSilverTwilight ]
  getModifiersFor (CardIdTarget cid) (OverTheThreshold a) = do
    card <- getCard cid
    let isSilverTwilight = SilverTwilight `member` toTraits card
    pure $ toModifiers a [ GainVictory 0 | isSilverTwilight ]
  getModifiersFor _ _ = pure []


overTheThreshold :: AgendaCard OverTheThreshold
overTheThreshold =
  agenda (2, A) OverTheThreshold Cards.overTheThreshold (Static 11)

instance HasAbilities OverTheThreshold where
  getAbilities (OverTheThreshold a) =
    [mkAbility a 1 $ ForcedAbility $ PhaseStep Timing.After HuntersMoveStep]

instance RunMessage OverTheThreshold where
  runMessage msg a@(OverTheThreshold attrs) = case msg of
    AdvanceAgenda aid | aid == toId attrs && onSide B attrs ->
      a <$ pushAll [AdvanceAgendaDeck (agendaDeckId attrs) (toSource attrs)]
    UseCardAbility _ (isSource attrs -> True) 1 _ _ -> do
      spectralEnemies <- selectWithField EnemyHealthDamage
        $ EnemyWithTrait Spectral
      enemyPairs <- catMaybes <$> for
        spectralEnemies
        \(enemy, damage) -> do
          humanoids <- selectList $ EnemyWithTrait Humanoid <> EnemyAt
            (locationWithEnemy enemy)
          pure $ guard (notNull humanoids) $> (enemy, damage, humanoids)
      lead <- getLead
      push $ chooseOrRunOneAtATime
        lead
        [ targetLabel
            enemy
            [ EnemyDamage humanoid $ nonAttack (EnemySource enemy) damage
            | humanoid <- humanoids
            ]
        | (enemy, damage, humanoids) <- enemyPairs
        ]
      pure a
    _ -> OverTheThreshold <$> runMessage msg attrs

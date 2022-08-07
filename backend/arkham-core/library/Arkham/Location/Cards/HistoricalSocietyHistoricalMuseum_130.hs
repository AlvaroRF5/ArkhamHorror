module Arkham.Location.Cards.HistoricalSocietyHistoricalMuseum_130
  ( historicalSocietyHistoricalMuseum_130
  , HistoricalSocietyHistoricalMuseum_130(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher hiding ( RevealLocation )
import Arkham.Message
import Arkham.SkillTest
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype HistoricalSocietyHistoricalMuseum_130 = HistoricalSocietyHistoricalMuseum_130 LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

historicalSocietyHistoricalMuseum_130
  :: LocationCard HistoricalSocietyHistoricalMuseum_130
historicalSocietyHistoricalMuseum_130 = location
  HistoricalSocietyHistoricalMuseum_130
  Cards.historicalSocietyHistoricalMuseum_130
  2
  (PerPlayer 1)

instance HasModifiersFor HistoricalSocietyHistoricalMuseum_130 where
  getModifiersFor (InvestigatorTarget _) (HistoricalSocietyHistoricalMuseum_130 attrs)
    = do
      mtarget <- getSkillTestTarget
      mAction <- getSkillTestAction
      case (mAction, mtarget) of
        (Just Action.Investigate, Just target) | isTarget attrs target ->
          pure $ toModifiers attrs [SkillCannotBeIncreased SkillIntellect]
        _ -> pure []
  getModifiersFor _ _ = pure []

instance HasAbilities HistoricalSocietyHistoricalMuseum_130 where
  getAbilities (HistoricalSocietyHistoricalMuseum_130 attrs) =
    withBaseAbilities
      attrs
      [ mkAbility attrs 1 $ ForcedAbility $ EnemySpawns
          Timing.When
          (LocationWithId $ toId attrs)
          AnyEnemy
      | not (locationRevealed attrs)
      ]

instance RunMessage HistoricalSocietyHistoricalMuseum_130 where
  runMessage msg l@(HistoricalSocietyHistoricalMuseum_130 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      l <$ push (RevealLocation Nothing $ toId attrs)
    _ -> HistoricalSocietyHistoricalMuseum_130 <$> runMessage msg attrs

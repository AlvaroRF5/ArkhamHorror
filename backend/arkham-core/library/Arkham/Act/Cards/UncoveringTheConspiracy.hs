module Arkham.Act.Cards.UncoveringTheConspiracy
  ( UncoveringTheConspiracy(..)
  , uncoveringTheConspiracy
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Types
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Card
import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.Resolution
import Arkham.Scenario.Deck
import Arkham.Source
import Arkham.Trait

newtype UncoveringTheConspiracy = UncoveringTheConspiracy ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

uncoveringTheConspiracy :: ActCard UncoveringTheConspiracy
uncoveringTheConspiracy =
  act (1, A) UncoveringTheConspiracy Cards.uncoveringTheConspiracy Nothing

instance HasAbilities UncoveringTheConspiracy where
  getAbilities (UncoveringTheConspiracy a) | onSide A a =
    [ restrictedAbility a 1 (ScenarioDeckWithCard CultistDeck)
      $ ActionAbility Nothing
      $ ActionCost 1
      <> GroupClueCost (PerPlayer 2) Anywhere
    , restrictedAbility
        a
        2
        (InVictoryDisplay
          (CardWithTrait Cultist <> CardIsUnique)
          (EqualTo $ Static 6)
        )
      $ Objective
      $ ForcedAbility AnyWindow
    ]
  getAbilities _ = []

instance RunMessage UncoveringTheConspiracy where
  runMessage msg a@(UncoveringTheConspiracy attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      a <$ push (DrawFromScenarioDeck iid CultistDeck (toTarget attrs) 1)
    DrewFromScenarioDeck iid CultistDeck target cards | isTarget attrs target ->
      a <$ pushAll
        (map (InvestigatorDrewEncounterCard iid)
        $ mapMaybe (preview _EncounterCard) cards
        )
    UseCardAbility iid source 2 _ _ | isSource attrs source ->
      a <$ push (AdvanceAct (toId attrs) (InvestigatorSource iid) AdvancedWithOther)
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs ->
      a <$ push (ScenarioResolution $ Resolution 1)
    _ -> UncoveringTheConspiracy <$> runMessage msg attrs

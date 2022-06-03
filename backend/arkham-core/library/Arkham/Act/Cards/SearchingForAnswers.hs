module Arkham.Act.Cards.SearchingForAnswers
  ( SearchingForAnswers(..)
  , searchingForAnswers
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Attrs
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Card
import Arkham.Card.EncounterCard
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Matcher hiding (RevealLocation)
import Arkham.Message
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype SearchingForAnswers = SearchingForAnswers ActAttrs
  deriving anyclass (IsAct, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

searchingForAnswers :: ActCard SearchingForAnswers
searchingForAnswers =
  act (1, A) SearchingForAnswers Cards.searchingForAnswers Nothing

instance HasAbilities SearchingForAnswers where
  getAbilities (SearchingForAnswers x) =
    [ mkAbility x 1 $ ForcedAbility $ Enters Timing.When You $ LocationWithTitle
        "The Hidden Chamber"
    ]

instance ActRunner env => RunMessage SearchingForAnswers where
  runMessage msg a@(SearchingForAnswers attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AdvanceAct (toId attrs) source AdvancedWithOther)
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs -> do
      unrevealedLocationIds <- selectList UnrevealedLocation
      hiddenChamber <- fromJustNote "must exist"
        <$> getId (LocationWithTitle "The Hidden Chamber")
      silasBishop <- EncounterCard <$> genEncounterCard Enemies.silasBishop
      a <$ pushAll
        ([ RevealLocation Nothing lid | lid <- unrevealedLocationIds ]
        <> [ MoveAllCluesTo (LocationTarget hiddenChamber)
           , CreateEnemyAt silasBishop hiddenChamber Nothing
           , AdvanceActDeck (actDeckId attrs) (toSource attrs)
           ]
        )
    _ -> SearchingForAnswers <$> runMessage msg attrs

module Arkham.Event.Cards.ThePaintedWorld
  ( thePaintedWorld
  , ThePaintedWorld(..)
  ) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Cost
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Game.Helpers
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher hiding ( DuringTurn )
import Arkham.Matcher qualified as Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Source
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Window

newtype ThePaintedWorld = ThePaintedWorld EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

thePaintedWorld :: EventCard ThePaintedWorld
thePaintedWorld = event ThePaintedWorld Cards.thePaintedWorld

instance RunMessage ThePaintedWorld where
  runMessage msg e@(ThePaintedWorld attrs) = case msg of
    InvestigatorPlayEvent iid eid _ windows' _ | eid == toId attrs -> do
      candidates <- fieldMap
        InvestigatorCardsUnderneath
        (filter (`cardMatch` (NonExceptional <> Matcher.EventCard)))
        iid
      let
        playableWindows = if null windows'
          then [Window Timing.When (DuringTurn iid)]
          else windows'
      playableCards <- filterM
        (getIsPlayable iid (toSource attrs) UnpaidCost playableWindows)
        candidates
      push $ InitiatePlayCardAsChoose
        iid
        (toCardId attrs)
        playableCards
        [ CreateEffect
            "03012"
            Nothing
            (CardIdSource $ toCardId attrs)
            (CardIdTarget $ toCardId attrs)
        ]
        True
      pure e
    _ -> ThePaintedWorld <$> runMessage msg attrs

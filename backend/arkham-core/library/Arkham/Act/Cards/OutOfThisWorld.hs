module Arkham.Act.Cards.OutOfThisWorld
  ( OutOfThisWorld(..)
  , outOfThisWorld
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Types
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Card
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype OutOfThisWorld = OutOfThisWorld ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

outOfThisWorld :: ActCard OutOfThisWorld
outOfThisWorld = act
  (1, A)
  OutOfThisWorld
  Cards.outOfThisWorld
  (Just $ GroupClueCost (PerPlayer 2) Anywhere)

instance HasAbilities OutOfThisWorld where
  getAbilities (OutOfThisWorld x) =
    withBaseAbilities x [mkAbility x 1 $ ActionAbility Nothing $ ActionCost 1]

instance RunMessage OutOfThisWorld where
  runMessage msg a@(OutOfThisWorld attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ _ | aid == actId && onSide B attrs -> do
      theEdgeOfTheUniverse <- getSetAsideCard Locations.theEdgeOfTheUniverse
      a <$ pushAll
        [ PlaceLocation theEdgeOfTheUniverse
        , AdvanceActDeck actDeckId (toSource attrs)
        ]
    UseCardAbility iid source 1 _ _ | isSource attrs source ->
      a <$ push (DiscardTopOfEncounterDeck iid 3 (Just $ toTarget attrs))
    DiscardedTopOfEncounterDeck iid cards target | isTarget attrs target -> do
      let locationCards = filterLocations cards
      a <$ unless
        (null locationCards)
        (pushAll
          [ FocusCards (map EncounterCard locationCards)
          , chooseOne
            iid
            [ TargetLabel
                (CardIdTarget $ toCardId location)
                [ RemoveFromEncounterDiscard location
                , InvestigatorDrewEncounterCard iid location
                ]
            | location <- locationCards
            ]
          , UnfocusCards
          ]
        )
    _ -> OutOfThisWorld <$> runMessage msg attrs

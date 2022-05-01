module Arkham.Location.Cards.Montmartre209
  ( montmartre209
  , Montmartre209(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Card
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Window (Window(..))
import Arkham.Window qualified as Window

newtype Montmartre209 = Montmartre209 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

montmartre209 :: LocationCard Montmartre209
montmartre209 = location
  Montmartre209
  Cards.montmartre209
  3
  (PerPlayer 1)
  Square
  [Diamond, Triangle, Equals, Moon]

instance HasAbilities Montmartre209 where
  getAbilities (Montmartre209 attrs) = withBaseAbilities
    attrs
    [ limitedAbility (GroupLimit PerRound 1)
      $ restrictedAbility attrs 1 Here
      $ ActionAbility Nothing
      $ ActionCost 1
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage env Montmartre209 where
  runMessage msg a@(Montmartre209 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      cards <- fmap (fmap toCardId) . filterM (getIsPlayable iid source UnpaidCost [Window Timing.When (Window.DuringTurn iid)]) =<< selectList (TopOfDeckOf Anyone)
      pushAll
        [ CreateEffect
          (toCardCode attrs)
          Nothing
          (toSource attrs)
          (InvestigatorTarget iid)
        , chooseOne iid
        $ Label "Play no cards" []
        : [ targetLabel card [InitiatePlayCard iid card Nothing True]
          | card <- cards
          ]
        ]
      pure a
    _ -> Montmartre209 <$> runMessage msg attrs

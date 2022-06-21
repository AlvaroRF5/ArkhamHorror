module Arkham.Location.Cards.PorteDeLAvancee
  ( porteDeLAvancee
  , PorteDeLAvancee(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
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

newtype PorteDeLAvancee = PorteDeLAvancee LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

porteDeLAvancee :: LocationCard PorteDeLAvancee
porteDeLAvancee = location
  PorteDeLAvancee
  Cards.porteDeLAvancee
  3
  (PerPlayer 1)
  Circle
  [Squiggle]

instance HasAbilities PorteDeLAvancee where
  getAbilities (PorteDeLAvancee a) = withBaseAbilities
    a
    [ restrictedAbility a 1 (Here <> AgendaExists AgendaWithAnyDoom)
      $ ActionAbility Nothing
      $ ActionCost 2
    ]

instance RunMessage PorteDeLAvancee where
  runMessage msg l@(PorteDeLAvancee attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      agendas <- selectList AgendaWithAnyDoom
      agendasWithOtherAgendas <- traverse
        (traverseToSnd (selectJust . NotAgenda . AgendaWithId))
        agendas
      push $ chooseOrRunOne
        iid
        [ targetLabel
            target
            [ RemoveDoom (AgendaTarget target) 1
            , PlaceDoom (AgendaTarget otherTarget) 1
            , PlaceClues (toTarget attrs) 2
            ]
        | (target, otherTarget) <- agendasWithOtherAgendas
        ]
      pure l
    _ -> PorteDeLAvancee <$> runMessage msg attrs

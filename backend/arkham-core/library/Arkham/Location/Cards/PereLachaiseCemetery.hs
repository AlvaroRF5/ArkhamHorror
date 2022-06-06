module Arkham.Location.Cards.PereLachaiseCemetery
  ( pereLachaiseCemetery
  , PereLachaiseCemetery(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Card
import Arkham.Target
import Arkham.Classes
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import qualified Arkham.Location.Cards as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Timing qualified as Timing

newtype PereLachaiseCemetery = PereLachaiseCemetery LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

pereLachaiseCemetery :: LocationCard PereLachaiseCemetery
pereLachaiseCemetery = location
  PereLachaiseCemetery
  Cards.pereLachaiseCemetery
  1
  (PerPlayer 2)
  T
  [Equals, Moon]

instance HasAbilities PereLachaiseCemetery where
  getAbilities (PereLachaiseCemetery attrs) = withBaseAbilities
    attrs
    [ restrictedAbility
        attrs
        1
        Here
        (ForcedAbility
          (SkillTestResult
            Timing.After
            You
            (WhileInvestigating $ LocationWithId $ toId attrs)
            (SuccessResult AnyValue)
          )
        )
    | locationRevealed attrs
    ]

instance RunMessage PereLachaiseCemetery where
  runMessage msg a@(PereLachaiseCemetery attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ CreateEffect (toCardCode attrs) Nothing source (InvestigatorTarget iid)
      pure a
    _ -> PereLachaiseCemetery <$> runMessage msg attrs

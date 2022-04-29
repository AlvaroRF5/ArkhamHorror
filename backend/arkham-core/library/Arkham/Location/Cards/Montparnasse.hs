module Arkham.Location.Cards.Montparnasse
  ( montparnasse
  , Montparnasse(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import qualified Arkham.Location.Cards as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType

newtype Montparnasse = Montparnasse LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

montparnasse :: LocationCard Montparnasse
montparnasse = location
  Montparnasse
  Cards.montparnasse
  2
  (PerPlayer 1)
  Circle
  [Heart, Star, Plus]

instance HasAbilities Montparnasse where
  getAbilities (Montparnasse attrs) = withBaseAbilities
    attrs
    [ limitedAbility (PlayerLimit PerRound 1)
      $ restrictedAbility attrs 1 Here
      $ FastAbility
      $ HandDiscardCost 1 AnyCard
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage env Montparnasse where
  runMessage msg a@(Montparnasse attrs) = case msg of
    UseCardAbility iid source _ 1 (DiscardCardPayment cards)
      | isSource attrs source -> do
        let
          countWillpower = count (== SkillWillpower) . cdSkills . toCardDef
          totalWillpower = sum $ map countWillpower cards
        a <$ push (TakeResources iid totalWillpower False)
    _ -> Montparnasse <$> runMessage msg attrs

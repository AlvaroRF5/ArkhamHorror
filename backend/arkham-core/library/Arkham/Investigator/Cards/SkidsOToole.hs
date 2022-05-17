module Arkham.Investigator.Cards.SkidsOToole
  ( SkidsOToole(..)
  , skidsOToole
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Cost
import Arkham.Criteria
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Matcher hiding ( DuringTurn )
import Arkham.Message
import Arkham.Target

newtype SkidsOToole = SkidsOToole InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

skidsOToole :: InvestigatorCard SkidsOToole
skidsOToole = investigator
  SkidsOToole
  Cards.skidsOToole
  Stats
    { health = 8
    , sanity = 6
    , willpower = 2
    , intellect = 3
    , combat = 3
    , agility = 4
    }

instance HasAbilities SkidsOToole where
  getAbilities (SkidsOToole a) =
    [ limitedAbility (PlayerLimit PerTurn 1)
        $ restrictedAbility a 1 (Self <> DuringTurn You)
        $ FastAbility
        $ ResourceCost 2
    ]

instance HasTokenValue env SkidsOToole where
  getTokenValue iid ElderSign (SkidsOToole attrs)
    | iid == investigatorId attrs = pure
    $ TokenValue ElderSign (PositiveModifier 2)
  getTokenValue _ token _ = pure $ TokenValue token mempty

instance InvestigatorRunner env => RunMessage env SkidsOToole where
  runMessage msg i@(SkidsOToole attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      i <$ push (GainActions (toId attrs) source 1)
    PassedSkillTest iid _ _ (TokenTarget token) _ _
      | iid == toId attrs && tokenFace token == ElderSign -> i
      <$ push (TakeResources iid 2 False)
    _ -> SkidsOToole <$> runMessage msg attrs

module Arkham.Treachery.Cards.CalledByTheMists
  ( calledByTheMists
  , CalledByTheMists(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Attrs

newtype CalledByTheMists = CalledByTheMists TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

calledByTheMists :: TreacheryCard CalledByTheMists
calledByTheMists = treachery CalledByTheMists Cards.calledByTheMists

instance HasAbilities CalledByTheMists where
  getAbilities (CalledByTheMists a) =
    [ restrictedAbility a 1 (InThreatAreaOf You)
      $ ForcedAbility
      $ InitiatedSkillTest Timing.After You AnySkillTest (AtLeast $ Static 4)
    , restrictedAbility a 2 OnSameLocation $ ActionAbility Nothing $ ActionCost
      2
    ]

instance RunMessage CalledByTheMists where
  runMessage msg t@(CalledByTheMists attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AttachTreachery (toId attrs) $ InvestigatorTarget iid)
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      t <$ push (InvestigatorAssignDamage iid source DamageAny 1 0)
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      t <$ push (Discard $ toTarget attrs)
    _ -> CalledByTheMists <$> runMessage msg attrs

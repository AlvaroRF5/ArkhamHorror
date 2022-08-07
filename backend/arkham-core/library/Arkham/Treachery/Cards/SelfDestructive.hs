module Arkham.Treachery.Cards.SelfDestructive
  ( selfDestructive
  , SelfDestructive(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Message
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype SelfDestructive = SelfDestructive TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

selfDestructive :: TreacheryCard SelfDestructive
selfDestructive = treachery SelfDestructive Cards.selfDestructive

instance HasAbilities SelfDestructive where
  getAbilities (SelfDestructive a) =
    [ restrictedAbility a 1 (InThreatAreaOf You) $ ForcedAbility $ EnemyDealtDamage
      Timing.When
      AnyDamageEffect
      AnyEnemy
      $ SourceOwnedBy You
    , restrictedAbility a 2 OnSameLocation $ ActionAbility Nothing $ ActionCost
      2
    ]

instance RunMessage SelfDestructive where
  runMessage msg t@(SelfDestructive attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AttachTreachery (toId attrs) $ InvestigatorTarget iid)
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      t <$ push (InvestigatorAssignDamage iid source DamageAny 1 0)
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      t <$ push (Discard $ toTarget attrs)
    _ -> SelfDestructive <$> runMessage msg attrs

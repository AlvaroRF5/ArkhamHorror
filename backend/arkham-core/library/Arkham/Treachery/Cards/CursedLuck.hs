module Arkham.Treachery.Cards.CursedLuck
  ( CursedLuck(..)
  , cursedLuck
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Source
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Runner
import Arkham.Treachery.Helpers
import Arkham.Treachery.Runner

newtype CursedLuck = CursedLuck TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cursedLuck :: TreacheryCard CursedLuck
cursedLuck = treachery CursedLuck Cards.cursedLuck

instance HasModifiersFor CursedLuck where
  getModifiersFor SkillTestSource{} (InvestigatorTarget iid) (CursedLuck attrs)
    = pure $ toModifiers
      attrs
      [ AnySkillValue (-1) | treacheryOnInvestigator iid attrs ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities CursedLuck where
  getAbilities (CursedLuck x) =
    [ restrictedAbility x 1 (InThreatAreaOf You)
      $ ForcedAbility
      $ SkillTestResult Timing.After You AnySkillTest
      $ SuccessResult
      $ AtLeast
      $ Static 1
    ]

instance TreacheryRunner env => RunMessage CursedLuck where
  runMessage msg t@(CursedLuck attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AttachTreachery (toId attrs) (InvestigatorTarget iid))
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      t <$ push (Discard $ toTarget attrs)
    _ -> CursedLuck <$> runMessage msg attrs

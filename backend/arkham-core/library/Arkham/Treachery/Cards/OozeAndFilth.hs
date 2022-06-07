module Arkham.Treachery.Cards.OozeAndFilth
  ( oozeAndFilth
  , OozeAndFilth(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Runner
import Arkham.Treachery.Helpers
import Arkham.Treachery.Runner

newtype OozeAndFilth = OozeAndFilth TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

oozeAndFilth :: TreacheryCard OozeAndFilth
oozeAndFilth = treachery OozeAndFilth Cards.oozeAndFilth

instance HasModifiersFor OozeAndFilth where
  getModifiersFor _ (LocationTarget _) (OozeAndFilth a) =
    pure $ toModifiers a [ShroudModifier 1]
  getModifiersFor _ _ _ = pure []

instance HasAbilities OozeAndFilth where
  getAbilities (OozeAndFilth a) =
    [mkAbility a 1 $ ForcedAbility $ RoundEnds Timing.When]

instance TreacheryRunner env => RunMessage OozeAndFilth where
  runMessage msg t@(OozeAndFilth attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      targetAgendas <- map AgendaTarget . setToList <$> getSet ()
      push $ chooseOrRunOne
        iid
        [ AttachTreachery (toId attrs) target | target <- targetAgendas ]
      pure t
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      t <$ push (Discard $ toTarget attrs)
    _ -> OozeAndFilth <$> runMessage msg attrs

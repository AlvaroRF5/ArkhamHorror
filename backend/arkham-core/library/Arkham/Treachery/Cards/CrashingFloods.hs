module Arkham.Treachery.Cards.CrashingFloods
  ( crashingFloods
  , CrashingFloods(..)
  ) where

import Arkham.Prelude

import Arkham.Agenda.Attrs ( Field (AgendaSequence) )
import Arkham.Agenda.Sequence qualified as AS
import Arkham.AgendaId
import Arkham.Classes
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.SkillType
import Arkham.Target
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype CrashingFloods = CrashingFloods TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

crashingFloods :: TreacheryCard CrashingFloods
crashingFloods = treachery CrashingFloods Cards.crashingFloods

getStep :: (Monad m, HasGame m) => Maybe AgendaId -> m Int
getStep Nothing = pure 3 -- if no agenda than act is 3
getStep (Just agenda) = do
  side <- fieldMap AgendaSequence AS.agendaStep agenda
  case side of
    AgendaStep step -> pure step

instance RunMessage CrashingFloods where
  runMessage msg t@(CrashingFloods attrs) = case msg of
    Revelation iid source | isSource attrs source -> t <$ pushAll
      [RevelationSkillTest iid source SkillAgility 3, Discard $ toTarget attrs]
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        n <- getStep =<< selectOne (AgendaWithSide AS.A)
        pushAll
          [ InvestigatorAssignDamage iid source DamageAny n 0
          , LoseActions iid source n
          ]
        pure t
    _ -> CrashingFloods <$> runMessage msg attrs

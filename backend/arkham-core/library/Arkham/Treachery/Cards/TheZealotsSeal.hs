module Arkham.Treachery.Cards.TheZealotsSeal where

import Arkham.Prelude

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.Message
import Arkham.Query
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Arkham.Treachery.Attrs
import Arkham.Treachery.Runner

newtype TheZealotsSeal = TheZealotsSeal TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theZealotsSeal :: TreacheryCard TheZealotsSeal
theZealotsSeal = treachery TheZealotsSeal Cards.theZealotsSeal

instance TreacheryRunner env => RunMessage env TheZealotsSeal where
  runMessage msg t@(TheZealotsSeal attrs@TreacheryAttrs {..}) = case msg of
    Revelation _ source | isSource attrs source -> do
      investigatorIds <- getInvestigatorIds
      -- we must unshift this first for other effects happen before
      t <$ for_
        investigatorIds
        (\iid' -> do
          handCardCount <- unCardCount <$> getCount iid'
          if handCardCount <= 3
            then push
              (InvestigatorAssignDamage iid' (toSource attrs) DamageAny 1 1)
            else push (RevelationSkillTest iid' source SkillWillpower 2)
        )
    FailedSkillTest iid _ (TreacherySource tid) SkillTestInitiatorTarget{} _ _
      | tid == treacheryId -> t
      <$ pushAll [RandomDiscard iid, RandomDiscard iid]
    _ -> TheZealotsSeal <$> runMessage msg attrs

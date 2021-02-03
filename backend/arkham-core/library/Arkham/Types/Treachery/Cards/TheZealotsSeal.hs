module Arkham.Types.Treachery.Cards.TheZealotsSeal where

import Arkham.Import

import Arkham.Types.Game.Helpers
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype TheZealotsSeal = TheZealotsSeal TreacheryAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

theZealotsSeal :: TreacheryId -> a -> TheZealotsSeal
theZealotsSeal uuid _ = TheZealotsSeal $ baseAttrs uuid "50024"

instance HasModifiersFor env TheZealotsSeal where
  getModifiersFor = noModifiersFor

instance HasActions env TheZealotsSeal where
  getActions i window (TheZealotsSeal attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env TheZealotsSeal where
  runMessage msg t@(TheZealotsSeal attrs@TreacheryAttrs {..}) = case msg of
    Revelation _ source | isSource attrs source -> do
      investigatorIds <- getInvestigatorIds
      -- we must unshift this first for other effects happen before
      unshiftMessage (Discard $ TreacheryTarget treacheryId)
      t <$ for_
        investigatorIds
        (\iid' -> do
          handCardCount <- unCardCount <$> getCount iid'
          if handCardCount <= 3
            then unshiftMessage
              (InvestigatorAssignDamage iid' (toSource attrs) DamageAny 1 1)
            else unshiftMessage
              (RevelationSkillTest iid' source SkillWillpower 2)
        )
    FailedSkillTest iid _ (TreacherySource tid) SkillTestInitiatorTarget{} _ _
      | tid == treacheryId -> t
      <$ unshiftMessages [RandomDiscard iid, RandomDiscard iid]
    _ -> TheZealotsSeal <$> runMessage msg attrs

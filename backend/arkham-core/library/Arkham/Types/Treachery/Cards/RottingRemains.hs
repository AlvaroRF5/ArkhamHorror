module Arkham.Types.Treachery.Cards.RottingRemains where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.TreacheryId


import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype RottingRemains = RottingRemains TreacheryAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rottingRemains :: TreacheryId -> a -> RottingRemains
rottingRemains uuid _ = RottingRemains $ baseAttrs uuid "01163"

instance HasModifiersFor env RottingRemains where
  getModifiersFor = noModifiersFor

instance HasActions env RottingRemains where
  getActions i window (RottingRemains attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env RottingRemains where
  runMessage msg t@(RottingRemains attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> t <$ unshiftMessages
      [ RevelationSkillTest iid source SkillWillpower 3
      , Discard (TreacheryTarget treacheryId)
      ]
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source -> t
      <$ unshiftMessage (InvestigatorAssignDamage iid source DamageAny 0 n)
    _ -> RottingRemains <$> runMessage msg attrs

module Arkham.Treachery.Cards.VortexOfTime
  ( vortexOfTime
  , VortexOfTime(..)
  ) where

import Arkham.Prelude

import Arkham.SkillType
import Arkham.Treachery.Attrs
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner
import Arkham.Classes
import Arkham.Id
import Arkham.Message
import Arkham.Target
import Arkham.Trait

newtype VortexOfTime = VortexOfTime TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

vortexOfTime :: TreacheryCard VortexOfTime
vortexOfTime = treachery VortexOfTime Cards.vortexOfTime

instance TreacheryRunner env => RunMessage VortexOfTime where
  runMessage msg t@(VortexOfTime attrs) = case msg of
    Revelation _iid source | isSource attrs source -> do
      sentinelHills <- getSetList @LocationId [SentinelHill]
      investigatorsAtSentinelHills <- concatMapM' getSetList sentinelHills
      t <$ pushAll
        ([ BeginSkillTest
             iid
             source
             (InvestigatorTarget iid)
             Nothing
             SkillWillpower
             4
         | iid <- investigatorsAtSentinelHills
         ]
        <> [Discard $ toTarget attrs]
        )
    FailedSkillTest iid _ source SkillTestTarget{} _ _
      | isSource attrs source -> t
      <$ push (InvestigatorAssignDamage iid source DamageAny 2 0)
    _ -> VortexOfTime <$> runMessage msg attrs

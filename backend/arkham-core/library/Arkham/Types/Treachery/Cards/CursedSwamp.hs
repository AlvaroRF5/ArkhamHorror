module Arkham.Types.Treachery.Cards.CursedSwamp
  ( CursedSwamp(..)
  , cursedSwamp
  ) where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.TreacheryId


import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner

newtype CursedSwamp = CursedSwamp TreacheryAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cursedSwamp :: TreacheryId -> a -> CursedSwamp
cursedSwamp uuid _ = CursedSwamp $ baseAttrs uuid "81024"

instance
  ( HasId LocationId env InvestigatorId
  , HasSet Trait env LocationId
  )
  => HasModifiersFor env CursedSwamp where
  getModifiersFor (SkillTestSource _ _ source _ _) (InvestigatorTarget iid) (CursedSwamp attrs)
    | isSource attrs source
    = do
      locationId <- getId @LocationId iid
      isBayou <- member Bayou <$> getSet locationId
      pure $ toModifiers attrs [ CannotCommitCards | isBayou ]
  getModifiersFor _ _ _ = pure []

instance HasActions env CursedSwamp where
  getActions i window (CursedSwamp attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env CursedSwamp where
  runMessage msg t@(CursedSwamp attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> t <$ unshiftMessages
      [ RevelationSkillTest iid source SkillWillpower 3
      , Discard (TreacheryTarget treacheryId)
      ]
    FailedSkillTest iid _ (TreacherySource tid) SkillTestInitiatorTarget{} _ n
      | tid == treacheryId -> t <$ unshiftMessage
        (InvestigatorAssignDamage
          iid
          (TreacherySource treacheryId)
          DamageAny
          n
          0
        )
    _ -> CursedSwamp <$> runMessage msg attrs

{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Treachery.Cards.CursedSwamp
  ( CursedSwamp(..)
  , cursedSwamp
  )
where

import Arkham.Import

import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner

newtype CursedSwamp = CursedSwamp Attrs
  deriving newtype (Show, ToJSON, FromJSON)

cursedSwamp :: TreacheryId -> a -> CursedSwamp
cursedSwamp uuid _ = CursedSwamp $ baseAttrs uuid "81024"

instance
  ( HasId LocationId env InvestigatorId
  , HasSet Trait env LocationId
  )
  => HasModifiersFor env CursedSwamp where
  getModifiersFor (SkillTestSource _ _ source _) (InvestigatorTarget iid) (CursedSwamp attrs)
    | isSource attrs source
    = do
      locationId <- getId @LocationId iid
      isBayou <- member Bayou <$> getSet locationId
      pure $ toModifiers attrs [ CannotCommitCards | isBayou ]
  getModifiersFor _ _ _ = pure []

instance HasActions env CursedSwamp where
  getActions i window (CursedSwamp attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env CursedSwamp where
  runMessage msg t@(CursedSwamp attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      t <$ unshiftMessages
        [ RevelationSkillTest iid source SkillWillpower 3
        , Discard (TreacheryTarget treacheryId)
        ]
    FailedSkillTest iid _ (TreacherySource tid) SkillTestInitiatorTarget{} n
      | tid == treacheryId -> t <$ unshiftMessage
        (InvestigatorAssignDamage iid (TreacherySource treacheryId) n 0)
    _ -> CursedSwamp <$> runMessage msg attrs

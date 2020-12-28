{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Treachery.Cards.Indebted
  ( Indebted(..)
  , indebted
  )
where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner

newtype Indebted = Indebted Attrs
  deriving newtype (Show, ToJSON, FromJSON)

indebted :: TreacheryId -> Maybe InvestigatorId -> Indebted
indebted uuid iid = Indebted $ weaknessAttrs uuid iid "02037"

instance HasModifiersFor env Indebted where
  getModifiersFor _ (InvestigatorTarget iid) (Indebted attrs) =
    pure $ toModifiers
      attrs
      [ StartingResources (-2) | treacheryOnInvestigator iid attrs ]
  getModifiersFor _ _ _ = pure []

instance HasActions env Indebted where
  getActions iid window (Indebted attrs) = getActions iid window attrs

instance (TreacheryRunner env) => RunMessage env Indebted where
  runMessage msg t@(Indebted attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      t <$ unshiftMessage (AttachTreachery treacheryId $ InvestigatorTarget iid)
    _ -> Indebted <$> runMessage msg attrs

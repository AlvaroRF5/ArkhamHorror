{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Treachery.Cards.AbandonedAndAlone where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype AbandonedAndAlone = AbandonedAndAlone Attrs
  deriving newtype (Show, ToJSON, FromJSON)

abandonedAndAlone :: TreacheryId -> Maybe InvestigatorId -> AbandonedAndAlone
abandonedAndAlone uuid iid = AbandonedAndAlone $ weaknessAttrs uuid iid "01015"

instance HasModifiersFor env AbandonedAndAlone where
  getModifiersFor = noModifiersFor

instance HasActions env AbandonedAndAlone where
  getActions i window (AbandonedAndAlone attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env AbandonedAndAlone where
  runMessage msg t@(AbandonedAndAlone attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      t <$ unshiftMessages
        [ InvestigatorDirectDamage iid source 0 2
        , RemoveDiscardFromGame iid
        , Discard $ toTarget attrs
        ]
    _ -> AbandonedAndAlone <$> runMessage msg attrs

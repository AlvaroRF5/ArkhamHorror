{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event.Cards.HotStreak4 where

import Arkham.Import

import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner

newtype HotStreak4 = HotStreak4 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

hotStreak4 :: InvestigatorId -> EventId -> HotStreak4
hotStreak4 iid uuid = HotStreak4 $ baseAttrs iid uuid "01057"

instance HasModifiersFor env HotStreak4 where
  getModifiersFor = noModifiersFor

instance HasActions env HotStreak4 where
  getActions i window (HotStreak4 attrs) = getActions i window attrs

instance (EventRunner env) => RunMessage env HotStreak4 where
  runMessage msg e@(HotStreak4 attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId ->
      e <$ unshiftMessages
        [TakeResources iid 10 False, Discard (EventTarget eid)]
    _ -> HotStreak4 <$> runMessage msg attrs

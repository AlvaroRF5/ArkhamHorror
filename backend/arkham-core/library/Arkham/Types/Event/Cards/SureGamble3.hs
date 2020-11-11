{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event.Cards.SureGamble3 where

import Arkham.Import

import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner

newtype SureGamble3 = SureGamble3 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

sureGamble3 :: InvestigatorId -> EventId -> SureGamble3
sureGamble3 iid uuid = SureGamble3 $ baseAttrs iid uuid "01088"

instance HasModifiersFor env SureGamble3 where
  getModifiersFor = noModifiersFor

instance HasActions env SureGamble3 where
  getActions i window (SureGamble3 attrs) = getActions i window attrs

instance (EventRunner env) => RunMessage env SureGamble3 where
  runMessage msg (SureGamble3 attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent _ eid (Just target@(TokenTarget _))
      | eid == eventId -> SureGamble3 <$> runMessage
        msg
        (attrs
        & (modifiersFor %~ insertWith (<>) target [NegativeToPositive])
        & (resolved .~ True)
        )
    _ -> SureGamble3 <$> runMessage msg attrs

module Arkham.Helpers.Event where

import Arkham.Prelude

import Arkham.Card.CardDef
import Arkham.Classes.Entity
import Arkham.Classes.HasQueue
import Arkham.Event.Attrs
import Arkham.GameEnv
import Arkham.Message
import Arkham.Target

unshiftEffect :: EventAttrs -> Target -> GameT ()
unshiftEffect attrs target = pushAll
  [ CreateEffect (cdCardCode $ toCardDef attrs) Nothing (toSource attrs) target
  , Discard $ toTarget attrs
  ]

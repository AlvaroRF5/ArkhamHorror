module Arkham.Types.Event.Cards.DevilsLuck
  ( devilsLuck
  , DevilsLuck(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.Message
import Arkham.Types.Window (Window(..))
import Arkham.Types.Window qualified as Window

newtype DevilsLuck = DevilsLuck EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

devilsLuck :: EventCard DevilsLuck
devilsLuck = event DevilsLuck Cards.devilsLuck

instance EventRunner env => RunMessage env DevilsLuck where
  runMessage msg e@(DevilsLuck attrs) = case msg of
    InvestigatorPlayEvent iid eid _ [Window _ (Window.WouldTakeDamageOrHorror _ _ damage horror)]
      | eid == toId attrs
      -> do
        e <$ pushAll
          [ chooseAmounts
            iid
            "Amount of Damage/Horror to cancel"
            10
            ([ ("Damage", (0, damage)) | damage > 0 ]
            <> [ ("Horror", (0, horror)) | horror > 0 ]
            )
            (toTarget attrs)
          , Discard (toTarget attrs)
          ]
    ResolveAmounts iid choices target | isTarget attrs target -> do
      let
        choicesMap = mapFromList @(HashMap Text Int) choices
        damageAmount = findWithDefault 0 "Damage" choicesMap
        horrorAmount = findWithDefault 0 "Horror" choicesMap
      e <$ pushAll
        ([ CancelDamage iid damageAmount | damageAmount > 0 ]
        <> [ CancelHorror iid horrorAmount | horrorAmount > 0 ]
        )
    _ -> DevilsLuck <$> runMessage msg attrs

module Arkham.Event.Cards.GritYourTeeth
  ( gritYourTeeth
  , GritYourTeeth(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Classes
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.Event.Attrs
import Arkham.Event.Helpers
import Arkham.Event.Runner
import Arkham.Message
import Arkham.Modifier
import Arkham.Target

newtype GritYourTeeth = GritYourTeeth EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

gritYourTeeth :: EventCard GritYourTeeth
gritYourTeeth = event GritYourTeeth Cards.gritYourTeeth

instance EventRunner env => RunMessage GritYourTeeth where
  runMessage msg e@(GritYourTeeth attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      e <$ pushAll
        [ CreateWindowModifierEffect
          EffectRoundWindow
          (EffectModifiers $ toModifiers attrs [AnySkillValue 1])
          (toSource attrs)
          (InvestigatorTarget iid)
        , Discard (toTarget attrs)
        ]
    _ -> GritYourTeeth <$> runMessage msg attrs

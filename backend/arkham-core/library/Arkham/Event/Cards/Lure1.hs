module Arkham.Event.Cards.Lure1
  ( lure1
  , Lure1(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Criteria
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Helpers
import Arkham.Event.Runner
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype Lure1 = Lure1 EventAttrs
  deriving anyclass IsEvent
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

lure1 :: EventCard Lure1
lure1 = event Lure1 Cards.lure1

instance HasAbilities Lure1 where
  getAbilities (Lure1 attrs) =
    [restrictedAbility attrs 1 ControlsThis $ ForcedAbility $ RoundEnds Timing.When]

instance HasModifiersFor Lure1 where
  getModifiersFor _ (EnemyTarget _) (Lure1 attrs) =
    case eventAttachedTarget attrs of
      Just target@(LocationTarget _) ->
        pure $ toModifiers attrs [DuringEnemyPhaseMustMoveToward target]
      Just _ -> pure []
      Nothing -> pure []
  getModifiersFor _ _ _ = pure []

instance RunMessage Lure1 where
  runMessage msg e@(Lure1 attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      lid <- fieldMap
        InvestigatorLocation
        (fromJustNote "must be at a location")
        iid
      e <$ push (AttachEvent eid (LocationTarget lid))
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      e <$ push (Discard (toTarget attrs))
    _ -> Lure1 <$> runMessage msg attrs

module Arkham.Event.Cards.WingingIt
  ( wingingIt
  , WingingIt(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Helpers
import Arkham.Event.Runner
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Message
import Arkham.Projection
import Arkham.SkillType
import Arkham.Target
import Arkham.Zone qualified as Zone

newtype WingingIt = WingingIt EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wingingIt :: EventCard WingingIt
wingingIt = event WingingIt Cards.wingingIt

instance RunMessage WingingIt where
  runMessage msg e@(WingingIt attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ zone | eid == toId attrs -> do
      lid <- fieldMap
        InvestigatorLocation
        (fromJustNote "must be at a location")
        iid
      let
        eventResolution =
          if zone == Zone.FromDiscard then ShuffleIntoDeck iid else Discard
        modifiers =
          [ skillTestModifier attrs (InvestigatorTarget iid) (DiscoveredClues 1)
          | zone == Zone.FromDiscard
          ]
      e <$ pushAll
        (skillTestModifier attrs (LocationTarget lid) (ShroudModifier (-1))
        : modifiers
        <> [ Investigate iid lid (toSource attrs) Nothing SkillIntellect False
           , eventResolution (toTarget attrs)
           ]
        )
    _ -> WingingIt <$> runMessage msg attrs

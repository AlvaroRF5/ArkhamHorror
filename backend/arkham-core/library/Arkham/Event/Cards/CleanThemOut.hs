module Arkham.Event.Cards.CleanThemOut
  ( cleanThemOut
  , CleanThemOut(..)
  )
where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Classes
import Arkham.Event.Runner
import Arkham.Message
import Arkham.SkillType

newtype CleanThemOut = CleanThemOut EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cleanThemOut :: EventCard CleanThemOut
cleanThemOut =
  event CleanThemOut Cards.cleanThemOut

instance RunMessage CleanThemOut where
  runMessage msg e@(CleanThemOut attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      pushAll
        [ TakeResources iid 2 (toSource attrs) False
        , ChooseFightEnemy iid (toSource attrs) Nothing SkillCombat mempty False
        , discard attrs
        ]
      pure e
    _ -> CleanThemOut <$> runMessage msg attrs

module Arkham.Types.Event.Cards.BuryThemDeep
  ( buryThemDeep
  , BuryThemDeep(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Message
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Window
import qualified Arkham.Types.Window as Window

newtype BuryThemDeep = BuryThemDeep EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

buryThemDeep :: EventCard BuryThemDeep
buryThemDeep = event BuryThemDeep Cards.buryThemDeep

instance RunMessage env BuryThemDeep where
  runMessage msg e@(BuryThemDeep attrs) = case msg of
    InvestigatorPlayEvent _ eid _ [Window Timing.After (Window.EnemyDefeated _ enemyId)]
      | eid == toId attrs
      -> do
        push $ AddToVictory (toTarget attrs)
        e <$ replaceMessage
          (Discard $ EnemyTarget enemyId)
          [AddToVictory (EnemyTarget enemyId)]
    _ -> BuryThemDeep <$> runMessage msg attrs

module Arkham.Event.Cards.DynamiteBlast where

import Arkham.Prelude

import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Investigator.Types (Field (..))
import Arkham.Matcher hiding (NonAttackDamageEffect)
import Arkham.Message
import Arkham.Projection

newtype DynamiteBlast = DynamiteBlast EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dynamiteBlast :: EventCard DynamiteBlast
dynamiteBlast = event DynamiteBlast Cards.dynamiteBlast

instance RunMessage DynamiteBlast where
  runMessage msg e@(DynamiteBlast attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      currentLocation <- fieldJust InvestigatorLocation iid
      connectedLocations <- selectList $ AccessibleFrom $ LocationWithId currentLocation
      choices <- for (currentLocation : connectedLocations) $ \location -> do
        enemies <- selectList $ enemyAt location
        investigators <- selectList $ investigatorAt location
        pure
          ( location
          , map (\enid -> EnemyDamage enid $ nonAttack attrs 3) enemies
              <> map
                (\iid' -> assignDamage iid' attrs 3)
                investigators
          )
      let availableChoices = map (uncurry targetLabel) $ filter (notNull . snd) choices
      push $ chooseOne iid availableChoices
      pure e
    _ -> DynamiteBlast <$> runMessage msg attrs

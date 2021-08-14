module Arkham.Types.Event.Cards.DynamiteBlast2 where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Target

newtype DynamiteBlast2 = DynamiteBlast2 EventAttrs
  deriving anyclass IsEvent
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dynamiteBlast2 :: EventCard DynamiteBlast2
dynamiteBlast2 = event DynamiteBlast2 Cards.dynamiteBlast2

instance HasModifiersFor env DynamiteBlast2

instance HasAbilities env DynamiteBlast2 where
  getAbilities i window (DynamiteBlast2 attrs) = getAbilities i window attrs

instance (EventRunner env) => RunMessage env DynamiteBlast2 where
  -- TODO: Does not provoke attacks of opportunity
  runMessage msg e@(DynamiteBlast2 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ | eid == eventId -> do
      currentLocationId <- getId @LocationId iid
      connectedLocationIds <- map unConnectedLocationId
        <$> getSetList currentLocationId
      choices <- for (currentLocationId : connectedLocationIds) $ \lid -> do
        enemyIds <- getSetList lid
        investigatorIds <- getSetList @InvestigatorId lid
        pure
          ( lid
          , map (\enid -> EnemyDamage enid iid (EventSource eid) 3) enemyIds
            <> map
                 (\iid' -> InvestigatorAssignDamage
                   iid'
                   (EventSource eid)
                   DamageAny
                   3
                   0
                 )
                 investigatorIds
          )
      let
        availableChoices =
          map (\(l, c) -> TargetLabel (LocationTarget l) c)
            $ filter (notNull . snd) choices
      e <$ pushAll [chooseOne iid availableChoices, Discard (EventTarget eid)]
    _ -> DynamiteBlast2 <$> runMessage msg attrs

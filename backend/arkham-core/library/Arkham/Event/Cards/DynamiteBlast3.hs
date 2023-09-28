module Arkham.Event.Cards.DynamiteBlast3 where

import Arkham.Prelude

import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Helpers.Modifiers
import Arkham.Investigator.Types (Field (..))
import Arkham.Matcher hiding (NonAttackDamageEffect)
import Arkham.Message
import Arkham.Projection

newtype DynamiteBlast3 = DynamiteBlast3 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dynamiteBlast3 :: EventCard DynamiteBlast3
dynamiteBlast3 = event DynamiteBlast3 Cards.dynamiteBlast3

instance RunMessage DynamiteBlast3 where
  runMessage msg e@(DynamiteBlast3 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> do
      currentLocationId <-
        fieldMap
          InvestigatorLocation
          (fromJustNote "must be at a location")
          iid
      connectedLocationIds <-
        selectList
          $ AccessibleFrom
          $ LocationWithId
            currentLocationId
      canDealDamage <- withoutModifier iid CannotDealDamage
      choices <- for (currentLocationId : connectedLocationIds) $ \lid -> do
        enemyIds <- if canDealDamage then selectList (enemyAt lid) else pure []
        investigatorIds <- selectList $ InvestigatorAt $ LocationWithId lid
        pure
          ( lid
          , map (\enid -> EnemyDamage enid $ nonAttack attrs 3) enemyIds
              <> map
                ( \iid' ->
                    InvestigatorAssignDamage
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
          map (\(l, c) -> targetLabel l c) $ filter (notNull . snd) choices
      e <$ pushAll [chooseOne iid availableChoices]
    _ -> DynamiteBlast3 <$> runMessage msg attrs

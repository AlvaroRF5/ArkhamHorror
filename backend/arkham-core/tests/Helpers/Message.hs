module Helpers.Message where

import Arkham.Prelude

import Arkham.Action (Action)
import Arkham.Asset
import Arkham.Attack
import Arkham.Card
import Arkham.Classes
import Arkham.Enemy
import Arkham.Event
import Arkham.Helpers
import Arkham.Investigator
import Arkham.Location
import Arkham.Message
import Arkham.Name
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Arkham.Zone

playEvent :: Investigator -> Event -> Message
playEvent i e = InvestigatorPlayEvent (toId i) (toId e) Nothing [] FromHand

moveTo :: Investigator -> Location -> Message
moveTo i l = MoveTo (toSource i) (toId i) (toId l)

moveFrom :: Investigator -> Location -> Message
moveFrom i l = MoveFrom (toSource i) (toId i) (toId l)

moveAllTo :: Location -> Message
moveAllTo = MoveAllTo GameSource . toId

enemySpawn :: Location -> Enemy -> Message
enemySpawn l e = EnemySpawn Nothing (toId l) (toId e)

loadDeck :: Investigator -> [PlayerCard] -> Message
loadDeck i cs = LoadDeck (toId i) (Deck cs)

addToHand :: Investigator -> Card -> Message
addToHand i = AddToHand (toId i)

chooseEndTurn :: Investigator -> Message
chooseEndTurn i = ChooseEndTurn (toId i)

enemyAttack :: Investigator -> Enemy -> Message
enemyAttack i e = EnemyAttack (toId i) (toId e) DamageAny RegularAttack

fightEnemy :: Investigator -> Enemy -> Message
fightEnemy i e =
  FightEnemy (toId i) (toId e) (TestSource mempty) Nothing SkillCombat False

engageEnemy :: Investigator -> Enemy -> Message
engageEnemy i e = EngageEnemy (toId i) (toId e) False

disengageEnemy :: Investigator -> Enemy -> Message
disengageEnemy i e = DisengageEnemy (toId i) (toId e)

playAsset :: Investigator -> Asset -> Message
playAsset i a = InvestigatorPlayAsset (toId i) (toId a)

placedLocation :: Location -> Message
placedLocation l = PlacedLocation (toName l) (toCardCode l) (toId l)

playCard :: Investigator -> Card -> Message
playCard i c = PlayCard (toId i) c Nothing True

drawCards :: Investigator -> Int -> Message
drawCards i n = DrawCards (toId i) n False

investigate :: Investigator -> Location -> Message
investigate i l =
  Investigate (toId i) (toId l) (TestSource mempty) Nothing SkillIntellect False

beginSkillTest :: Investigator -> SkillType -> Int -> Message
beginSkillTest i =
  BeginSkillTest (toId i) (TestSource mempty) TestTarget Nothing

beginActionSkillTest :: Investigator -> Action -> Maybe Target -> SkillType -> Int -> Message
beginActionSkillTest i a mt =
  BeginSkillTest (toId i) (TestSource mempty) target (Just a)
 where
   target = fromMaybe TestTarget mt

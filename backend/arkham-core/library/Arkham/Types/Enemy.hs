module Arkham.Types.Enemy
  ( lookupEnemy
  , baseEnemy
  , isEngaged
  , isUnique
  , getEngagedInvestigators
  , getBearer
  , getEnemyVictory
  , Enemy
  ) where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Trait (Trait)
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Cards
import Arkham.Types.Enemy.Runner

data Enemy
  = MobEnforcer' MobEnforcer
  | SilverTwilightAcolyte' SilverTwilightAcolyte
  | StubbornDetective' StubbornDetective
  | GhoulPriest' GhoulPriest
  | FleshEater' FleshEater
  | IcyGhoul' IcyGhoul
  | TheMaskedHunter' TheMaskedHunter
  | WolfManDrew' WolfManDrew
  | HermanCollins' HermanCollins
  | PeterWarren' PeterWarren
  | VictoriaDevereux' VictoriaDevereux
  | RuthTurner' RuthTurner
  | Umordhoth' Umordhoth
  | SwarmOfRats' SwarmOfRats
  | GhoulMinion' GhoulMinion
  | RavenousGhoul' RavenousGhoul
  | Acolyte' Acolyte
  | WizardOfTheOrder' WizardOfTheOrder
  | HuntingNightgaunt' HuntingNightgaunt
  | ScreechingByakhee' ScreechingByakhee
  | YithianObserver' YithianObserver
  | RelentlessDarkYoung' RelentlessDarkYoung
  | GoatSpawn' GoatSpawn
  | YoungDeepOne' YoungDeepOne
  | TheExperiment' TheExperiment
  | CloverClubPitBoss' CloverClubPitBoss
  | Thrall' Thrall
  | WizardOfYogSothoth' WizardOfYogSothoth
  | Whippoorwill' Whippoorwill
  | AvianThrall' AvianThrall
  | LupineThrall' LupineThrall
  | OBannionsThug' OBannionsThug
  | Mobster' Mobster
  | ConglomerationOfSpheres' ConglomerationOfSpheres
  | ServantOfTheLurker' ServantOfTheLurker
  | HuntingHorror' HuntingHorror
  | GrapplingHorror' GrapplingHorror
  | EmergentMonstrosity' EmergentMonstrosity
  | CorpseHungryGhoul' CorpseHungryGhoul
  | GhoulFromTheDepths' GhoulFromTheDepths
  | Narogath' Narogath
  | GraveEater' GraveEater
  | AcolyteOfUmordhoth' AcolyteOfUmordhoth
  | DiscipleOfTheDevourer' DiscipleOfTheDevourer
  | CorpseTaker' CorpseTaker
  | JeremiahPierce' JeremiahPierce
  | BillyCooper' BillyCooper
  | AlmaHill' AlmaHill
  | BogGator' BogGator
  | SwampLeech' SwampLeech
  | TheRougarou' TheRougarou
  | SlimeCoveredDhole' SlimeCoveredDhole
  | MarshGug' MarshGug
  | DarkYoungHost' DarkYoungHost
  | BaseEnemy' BaseEnemy
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

newtype BaseEnemy = BaseEnemy EnemyAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

baseEnemy :: EnemyId -> CardCode -> (EnemyAttrs -> EnemyAttrs) -> Enemy
baseEnemy a b f = BaseEnemy' . BaseEnemy $ baseAttrs a b f

instance ActionRunner env => HasActions env BaseEnemy where
  getActions investigator window (BaseEnemy attrs) =
    getActions investigator window attrs

instance HasModifiersFor env BaseEnemy where
  getModifiersFor = noModifiersFor

instance (EnemyRunner env) => RunMessage env BaseEnemy where
  runMessage msg (BaseEnemy attrs) = BaseEnemy <$> runMessage msg attrs

actionFromMessage :: Message -> Maybe Action
actionFromMessage (ActivateCardAbilityAction _ ability) =
  case abilityType ability of
    ActionAbility maction _ -> maction
    _ -> Nothing
actionFromMessage _ = Nothing

preventedByModifier :: EnemyAttrs -> Message -> Modifier -> Bool
preventedByModifier EnemyAttrs {..} msg (Modifier _ (CannotTakeAction matcher))
  = case actionFromMessage msg of
    Just action -> case matcher of
      IsAction a -> a == action
      EnemyAction a traits ->
        a == action && not (null $ setFromList traits `intersect` enemyTraits)
      FirstOneOf _ -> False -- TODO: We can't tell here
    Nothing -> False
preventedByModifier _ _ _ = False

instance ActionRunner env => HasActions env Enemy where
  getActions investigator window enemy = do
    modifiers' <- getModifiersFor
      (toSource enemy)
      (InvestigatorTarget investigator)
      ()
    actions <- defaultGetActions investigator window enemy
    pure $ filter
      (\action ->
        not $ any (preventedByModifier (toAttrs enemy) action) modifiers'
      )
      actions

deriving anyclass instance
  ( HasId LocationId env InvestigatorId
  , HasCount RemainingSanity env InvestigatorId
  , HasCount CardCount env InvestigatorId
  , HasCount PlayerCount env ()
  , HasSet InvestigatorId env LocationId
  , HasSet ConnectedLocationId env LocationId
  , HasSet Trait env AssetId
  , HasSet Trait env LocationId
  )
  => HasModifiersFor env Enemy

instance Entity Enemy where
  type EntityId Enemy = EnemyId
  type EntityAttrs Enemy = EnemyAttrs

instance NamedEntity Enemy where
  toName = toName . toAttrs

instance TargetEntity Enemy where
  toTarget = toTarget . toAttrs
  isTarget = isTarget . toAttrs

instance SourceEntity Enemy where
  toSource = toSource . toAttrs
  isSource = isSource . toAttrs

instance (EnemyRunner env) => RunMessage env Enemy where
  runMessage msg e = do
    modifiers' <- getModifiersFor (toSource e) (toTarget e) ()
    if any isBlank modifiers' && not (isBlanked msg)
      then runMessage (Blanked msg) e
      else defaultRunMessage msg e

instance HasVictoryPoints Enemy where
  getVictoryPoints = enemyVictory . toAttrs

instance HasCount DoomCount env Enemy where
  getCount = pure . DoomCount . enemyDoom . toAttrs

instance HasCount HealthDamageCount env Enemy where
  getCount = pure . HealthDamageCount . enemyHealthDamage . toAttrs

instance HasCount SanityDamageCount env Enemy where
  getCount = pure . SanityDamageCount . enemySanityDamage . toAttrs

instance HasId LocationId env Enemy where
  getId = pure . enemyLocation . toAttrs

instance HasSet TreacheryId env Enemy where
  getSet = pure . enemyTreacheries . toAttrs

instance HasSet AssetId env Enemy where
  getSet = pure . enemyAssets . toAttrs

instance IsCard Enemy where
  getCardId = getCardId . toAttrs
  getCardCode = getCardCode . toAttrs
  getTraits = getTraits . toAttrs
  getKeywords = getKeywords . toAttrs

instance HasDamage Enemy where
  getDamage = (, 0) . enemyDamage . toAttrs

lookupEnemy :: CardCode -> (EnemyId -> Enemy)
lookupEnemy cardCode =
  fromJustNote ("Unknown enemy: " <> pack (show cardCode))
    $ lookup cardCode allEnemies

allEnemies :: HashMap CardCode (EnemyId -> Enemy)
allEnemies = mapFromList
  [ ("01101", MobEnforcer' . mobEnforcer)
  , ("01102", SilverTwilightAcolyte' . silverTwilightAcolyte)
  , ("01103", StubbornDetective' . stubbornDetective)
  , ("01116", GhoulPriest' . ghoulPriest)
  , ("01118", FleshEater' . fleshEater)
  , ("01119", IcyGhoul' . icyGhoul)
  , ("01121b", TheMaskedHunter' . theMaskedHunter)
  , ("01137", WolfManDrew' . wolfManDrew)
  , ("01138", HermanCollins' . hermanCollins)
  , ("01139", PeterWarren' . peterWarren)
  , ("01140", VictoriaDevereux' . victoriaDevereux)
  , ("01141", RuthTurner' . ruthTurner)
  , ("01157", Umordhoth' . umordhoth)
  , ("01159", SwarmOfRats' . swarmOfRats)
  , ("01160", GhoulMinion' . ghoulMinion)
  , ("01161", RavenousGhoul' . ravenousGhoul)
  , ("01169", Acolyte' . acolyte)
  , ("01170", WizardOfTheOrder' . wizardOfTheOrder)
  , ("01172", HuntingNightgaunt' . huntingNightgaunt)
  , ("01175", ScreechingByakhee' . screechingByakhee)
  , ("01177", YithianObserver' . yithianObserver)
  , ("01179", RelentlessDarkYoung' . relentlessDarkYoung)
  , ("01180", GoatSpawn' . goatSpawn)
  , ("01181", YoungDeepOne' . youngDeepOne)
  , ("02058", TheExperiment' . theExperiment)
  , ("02078", CloverClubPitBoss' . cloverClubPitBoss)
  , ("02086", Thrall' . thrall)
  , ("02087", WizardOfYogSothoth' . wizardOfYogSothoth)
  , ("02090", Whippoorwill' . whippoorwill)
  , ("02094", AvianThrall' . avianThrall)
  , ("02095", LupineThrall' . lupineThrall)
  , ("02097", OBannionsThug' . oBannionsThug)
  , ("02098", Mobster' . mobster)
  , ("02103", ConglomerationOfSpheres' . conglomerationOfSpheres)
  , ("02104", ServantOfTheLurker' . servantOfTheLurker)
  , ("02141", HuntingHorror' . huntingHorror)
  , ("02182", GrapplingHorror' . grapplingHorror)
  , ("02183", EmergentMonstrosity' . emergentMonstrosity)
  , ("50022", CorpseHungryGhoul' . corpseHungryGhoul)
  , ("50023", GhoulFromTheDepths' . ghoulFromTheDepths)
  , ("50026b", Narogath' . narogath)
  , ("50038", GraveEater' . graveEater)
  , ("50039", AcolyteOfUmordhoth' . acolyteOfUmordhoth)
  , ("50041", DiscipleOfTheDevourer' . discipleOfTheDevourer)
  , ("50042", CorpseTaker' . corpseTaker)
  , ("50044", JeremiahPierce' . jeremiahPierce)
  , ("50045", BillyCooper' . billyCooper)
  , ("50046", AlmaHill' . almaHill)
  , ("81022", BogGator' . bogGator)
  , ("81023", SwampLeech' . swampLeech)
  , ("81028", TheRougarou' . theRougarou)
  , ("81031", SlimeCoveredDhole' . slimeCoveredDhole)
  , ("81032", MarshGug' . marshGug)
  , ("81033", DarkYoungHost' . darkYoungHost)
  , ("enemy", \eid -> baseEnemy eid "enemy" id)
  ]

isEngaged :: Enemy -> Bool
isEngaged = not . null . enemyEngagedInvestigators . toAttrs

isUnique :: Enemy -> Bool
isUnique = enemyUnique . toAttrs

instance Exhaustable Enemy where
  isExhausted = enemyExhausted . toAttrs

getEngagedInvestigators :: Enemy -> HashSet InvestigatorId
getEngagedInvestigators = enemyEngagedInvestigators . toAttrs

getEnemyVictory :: Enemy -> Maybe Int
getEnemyVictory = enemyVictory . toAttrs

getBearer :: Enemy -> Maybe InvestigatorId
getBearer enemy = case enemyPrey (toAttrs enemy) of
  Bearer iid -> Just (InvestigatorId $ unBearerId iid)
  _ -> Nothing

isBlanked :: Message -> Bool
isBlanked Blanked{} = True
isBlanked _ = False

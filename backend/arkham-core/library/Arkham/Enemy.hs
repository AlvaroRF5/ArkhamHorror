{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.Enemy (
  module Arkham.Enemy,
) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Enemy.Enemies
import Arkham.Enemy.Runner
import Arkham.Id
import Arkham.Matcher

createEnemy :: (HasCallStack, IsCard a) => a -> EnemyId -> Enemy
createEnemy a eid = lookupEnemy (toCardCode a) eid (toCardId a)

instance RunMessage Enemy where
  runMessage (SendMessage target msg) e | e `is` target = do
    runMessage msg e
  runMessage msg e@(Enemy x) = do
    -- we must check that an enemy exists when grabbing modifiers
    -- as some messages are not masked when targetting cards in the
    -- discard.
    allEnemyIds <- select AnyEnemy
    modifiers' <-
      if toId e `elem` allEnemyIds
        then getModifiers (toTarget e)
        else pure []
    let msg' = if Blank `elem` modifiers' then Blanked msg else msg
    Enemy <$> runMessage msg' x

lookupEnemy :: HasCallStack => CardCode -> EnemyId -> CardId -> Enemy
lookupEnemy cardCode = case lookup cardCode allEnemies of
  Nothing -> error $ "Unknown enemy: " <> show cardCode
  Just (SomeEnemyCard a) -> \e c -> Enemy $ cbCardBuilder a c e

instance FromJSON Enemy where
  parseJSON = withObject "Enemy" $ \o -> do
    cCode <- o .: "cardCode"
    withEnemyCardCode cCode
      $ \(_ :: EnemyCard a) -> Enemy <$> parseJSON @a (Object o)

withEnemyCardCode
  :: CardCode -> (forall a. IsEnemy a => EnemyCard a -> r) -> r
withEnemyCardCode cCode f = case lookup cCode allEnemies of
  Nothing -> error $ "Unknown enemy: " <> show cCode
  Just (SomeEnemyCard a) -> f a

allEnemies :: Map CardCode SomeEnemyCard
allEnemies =
  mapFrom
    someEnemyCardCode
    [ -- Night of the Zealot
      -- weakness
      SomeEnemyCard mobEnforcer
    , SomeEnemyCard silverTwilightAcolyte
    , SomeEnemyCard stubbornDetective
    , -- The Gathering
      SomeEnemyCard ghoulPriest
    , SomeEnemyCard fleshEater
    , SomeEnemyCard icyGhoul
    , -- The Midnight Masks
      SomeEnemyCard theMaskedHunter
    , SomeEnemyCard wolfManDrew
    , SomeEnemyCard hermanCollins
    , SomeEnemyCard peterWarren
    , SomeEnemyCard victoriaDevereux
    , SomeEnemyCard ruthTurner
    , -- The Devourer Below
      SomeEnemyCard umordhoth
    , -- Rats
      SomeEnemyCard swarmOfRats
    , -- Ghouls
      SomeEnemyCard ghoulMinion
    , SomeEnemyCard ravenousGhoul
    , -- Dark Cult
      SomeEnemyCard acolyte
    , SomeEnemyCard wizardOfTheOrder
    , -- Nightgaunts
      SomeEnemyCard huntingNightgaunt
    , -- Agents of Hastur
      SomeEnemyCard screechingByakhee
    , -- Agents of Yog-Sothoth
      SomeEnemyCard yithianObserver
    , -- Agents of Shub-Niggurath
      SomeEnemyCard relentlessDarkYoung
    , SomeEnemyCard goatSpawn
    , -- Agents of Cthulhu
      SomeEnemyCard youngDeepOne
    , -- The Dunwich Legacy
      -- Extracurricular Activity
      SomeEnemyCard theExperiment
    , -- The House Always Wins
      SomeEnemyCard cloverClubPitBoss
    , -- Bishop's Thralls
      SomeEnemyCard thrall
    , SomeEnemyCard wizardOfYogSothoth
    , -- Whippoorwill
      SomeEnemyCard whippoorwill
    , -- Beast Thralls
      SomeEnemyCard avianThrall
    , SomeEnemyCard lupineThrall
    , -- Naomi's Crew
      SomeEnemyCard oBannionsThug
    , SomeEnemyCard mobster
    , -- Hideous Abominations
      SomeEnemyCard conglomerationOfSpheres
    , SomeEnemyCard servantOfTheLurker
    , -- The Miskatonic Museum
      SomeEnemyCard huntingHorror
    , -- The Essex County Express
      SomeEnemyCard grapplingHorror
    , SomeEnemyCard emergentMonstrosity
    , -- Blood on the Altar
      SomeEnemyCard silasBishop
    , SomeEnemyCard servantOfManyMouths
    , -- Undimensioned and Unseen
      SomeEnemyCard broodOfYogSothoth
    , -- Where Doom Awaits
      SomeEnemyCard sethBishop
    , SomeEnemyCard devoteeOfTheKey
    , SomeEnemyCard crazedShoggoth
    , -- Lost in Time and Space
      SomeEnemyCard yogSothoth
    , SomeEnemyCard interstellarTraveler
    , SomeEnemyCard yithianStarseeker
    , -- The Path to Carcosa
      -- signature
      SomeEnemyCard graveyardGhouls
    , -- weakness
      SomeEnemyCard theThingThatFollows
    , -- Curtain Call
      SomeEnemyCard theManInThePallidMask
    , SomeEnemyCard royalEmissary
    , -- The Last King
      SomeEnemyCard constanceDumaine
    , SomeEnemyCard jordanPerry
    , SomeEnemyCard ishimaruHaruko
    , SomeEnemyCard sebastienMoreau
    , SomeEnemyCard ashleighClarke
    , SomeEnemyCard dianneDevine
    , -- Byakhee
      SomeEnemyCard swiftByakhee
    , -- Inhabitants of Carcosa
      SomeEnemyCard beastOfAldebaran
    , SomeEnemyCard spawnOfHali
    , -- Hauntings
      SomeEnemyCard poltergeist
    , -- Hastur's Gift
      SomeEnemyCard maniac
    , SomeEnemyCard youngPsychopath
    , -- Cult of the Yellow Sign
      SomeEnemyCard fanatic
    , SomeEnemyCard agentOfTheKing
    , -- Decay and Filth
      SomeEnemyCard roachSwarm
    , -- Echoes of the Past
      SomeEnemyCard possessedOathspeaker
    , SomeEnemyCard seekerOfCarcosa
    , -- The Unspeakable Oath
      SomeEnemyCard danielChesterfield
    , SomeEnemyCard asylumGorger
    , SomeEnemyCard madPatient
    , -- A Phantom of Truth
      SomeEnemyCard theOrganistHopelessIDefiedHim
    , SomeEnemyCard theOrganistDrapedInMystery
    , SomeEnemyCard stealthyByakhee
    , -- The Pallid Mask
      SomeEnemyCard specterOfDeath
    , SomeEnemyCard catacombsDocent
    , SomeEnemyCard corpseDweller
    , -- Black Stars Rise
      SomeEnemyCard tidalTerror
    , SomeEnemyCard riftSeeker
    , -- Dim Carcosa
      SomeEnemyCard hasturTheKingInYellow
    , SomeEnemyCard hasturLordOfCarcosa
    , SomeEnemyCard hasturTheTatteredKing
    , SomeEnemyCard creatureOutOfDemhe
    , SomeEnemyCard wingedOne
    , -- The Forgotten Age
      -- signature
      SomeEnemyCard serpentsOfYig
    , -- The Untamed Wilds
      SomeEnemyCard ichtaca
    , -- The Doom of Eztli
      SomeEnemyCard harbingerOfValusia
    , -- Serpents
      SomeEnemyCard pitViper
    , SomeEnemyCard boaConstrictor
    , -- Agents of Yig
      SomeEnemyCard broodOfYig
    , SomeEnemyCard serpentFromYoth
    , -- Guardians of Time
      SomeEnemyCard eztliGuardian
    , -- Pnakotic Brotherhood
      SomeEnemyCard brotherhoodCultist
    , -- Yig's Venom
      SomeEnemyCard fangOfYig
    , -- Threads of Fate
      SomeEnemyCard harlanEarnstoneCrazedByTheCurse
    , SomeEnemyCard henryDeveauAlejandrosKidnapper
    , SomeEnemyCard mariaDeSilvaKnowsMoreThanSheLetsOn
    , -- The Boundary Beyond
      SomeEnemyCard padmaAmrita
    , SomeEnemyCard serpentOfTenochtitlan
    , SomeEnemyCard handOfTheBrotherhood
    , -- Heart of the Elders
      --- Pillars of Judgement
      SomeEnemyCard theWingedSerpent
    , SomeEnemyCard apexStrangleweed
    , SomeEnemyCard basilisk
    , -- The City of Archives
      SomeEnemyCard keeperOfTheGreatLibrary
    , SomeEnemyCard scientistOfYith
    , SomeEnemyCard scholarFromYith
    , -- The Depths of Yoth
      SomeEnemyCard yig
    , SomeEnemyCard pitWarden
    , SomeEnemyCard eaterOfTheDepths
    , -- Shattered Aeons
      SomeEnemyCard ichtacaScionOfYig
    , SomeEnemyCard alejandroVela
    , SomeEnemyCard formlessSpawn
    , SomeEnemyCard temporalDevourer
    , SomeEnemyCard flyingPolyp
    , -- The Circle Undone
      -- signature
      SomeEnemyCard hoods
    , -- The Witching Hour
      SomeEnemyCard anetteMason
    , -- At Death's Doorstep
      SomeEnemyCard josefMeiger
    , -- The Watcher
      SomeEnemyCard theSpectralWatcher
    , -- Agents of Azathoth
      SomeEnemyCard piperOfAzathoth
    , -- Anette's Coven
      SomeEnemyCard covenInitiate
    , SomeEnemyCard priestessOfTheCoven
    , -- Silver Twilight Lodge
      SomeEnemyCard lodgeNeophyte
    , SomeEnemyCard keeperOfSecrets
    , -- Spectral Predators
      SomeEnemyCard netherMist
    , SomeEnemyCard shadowHound
    , -- Trapped Spirits
      SomeEnemyCard wraith
    , -- The Secret Name
      SomeEnemyCard brownJenkin
    , SomeEnemyCard nahab
    , -- The Wages of Sin
      SomeEnemyCard heretic_A
    , SomeEnemyCard heretic_C
    , SomeEnemyCard heretic_E
    , SomeEnemyCard heretic_G
    , SomeEnemyCard heretic_I
    , SomeEnemyCard heretic_K
    , SomeEnemyCard vengefulWitch
    , SomeEnemyCard malevolentSpirit
    , SomeEnemyCard reanimatedDead
    , -- For the Greater Good
      SomeEnemyCard nathanWickMasterOfInitiation
    , SomeEnemyCard nathanWickMasterOfIndoctrination
    , SomeEnemyCard lodgeJailor
    , SomeEnemyCard cellKeeper
    , SomeEnemyCard summonedBeast
    , SomeEnemyCard knightOfTheInnerCircle
    , SomeEnemyCard knightOfTheOuterVoid
    , -- Union and Disillusion
      SomeEnemyCard gavriellaMizrah
    , SomeEnemyCard jeromeDavids
    , SomeEnemyCard pennyWhite
    , SomeEnemyCard valentinoRivas
    , SomeEnemyCard whippoorwillUnionAndDisillusion
    , SomeEnemyCard spectralRaven
    , -- In the Clutches of Chaos
      --- Music of the Damned
      SomeEnemyCard anetteMasonReincarnatedEvil
    , SomeEnemyCard witnessOfChaos
    , --- Secrets of the Universe
      SomeEnemyCard carlSanfordDeathlessFanatic
    , SomeEnemyCard lodgeEnforcer
    , -- Before the Black Throne
      SomeEnemyCard mindlessDancer
    , SomeEnemyCard azathoth
    , -- The Dream-Eaters
      -- signature
      SomeEnemyCard tonysQuarry
    , SomeEnemyCard watcherFromAnotherDimension
    , -- rogue
      SomeEnemyCard guardianOfTheCrystallizer
    , -- basic weakness
      SomeEnemyCard yourWorstNightmare
    , --- Where the Gods Dwell
      -- mystic
      SomeEnemyCard unboundBeast
    , --- Beyond the Gates of Sleep
      SomeEnemyCard kamanThah
    , SomeEnemyCard nasht
    , SomeEnemyCard laboringGug
    , SomeEnemyCard ancientZoog
    , --- Waking Nightmare
      SomeEnemyCard suspiciousOrderly
    , SomeEnemyCard corruptedOrderly
    , --- Agents of Atlach-Nacha
      SomeEnemyCard greyWeaver
    , --- Agents of Nyarlathotep
      SomeEnemyCard theCrawlingMist
    , --- Spiders
      SomeEnemyCard spiderOfLeng
    , SomeEnemyCard swarmOfSpiders
    , --- Corsairs
      SomeEnemyCard corsairOfLeng
    , --- Zoogs
      SomeEnemyCard furtiveZoog
    , SomeEnemyCard stealthyZoog
    , SomeEnemyCard inconspicuousZoog
    , -- TheSearchForKadath
      SomeEnemyCard catsOfUlthar
    , SomeEnemyCard stalkingManticore
    , SomeEnemyCard hordeOfNight
    , SomeEnemyCard beingsOfIb
    , SomeEnemyCard priestOfAThousandMasks
    , SomeEnemyCard tenebrousNightgaunt
    , SomeEnemyCard packOfVooniths
    , SomeEnemyCard nightriders
    , -- Return to Night of the Zealot
      -- Return to the Gathering
      SomeEnemyCard corpseHungryGhoul
    , SomeEnemyCard ghoulFromTheDepths
    , -- Return to the Midnight Masks
      SomeEnemyCard narogath
    , -- Ghouls of Umordhoth
      SomeEnemyCard graveEater
    , SomeEnemyCard acolyteOfUmordhoth
    , -- The Devourer's Cult
      SomeEnemyCard discipleOfTheDevourer
    , SomeEnemyCard corpseTaker
    , -- Return to Cult of Umordhoth
      SomeEnemyCard jeremiahPierce
    , SomeEnemyCard billyCooper
    , SomeEnemyCard almaHill
    , -- Nathanial Cho
      SomeEnemyCard tommyMalloy
    , -- Curse of the Rougarou
      SomeEnemyCard bogGator
    , SomeEnemyCard swampLeech
    , SomeEnemyCard theRougarou
    , SomeEnemyCard slimeCoveredDhole
    , SomeEnemyCard marshGug
    , SomeEnemyCard darkYoungHost
    , -- Carnevale of Horrors
      SomeEnemyCard balefulReveler
    , SomeEnemyCard donLagorio
    , SomeEnemyCard elisabettaMagro
    , SomeEnemyCard salvatoreNeri
    , SomeEnemyCard savioCorvi
    , SomeEnemyCard cnidathqua
    , SomeEnemyCard poleman
    , SomeEnemyCard carnevaleSentinel
    , SomeEnemyCard writhingAppendage
    , -- Murder at the Excelsior Hotel
      SomeEnemyCard arkhamOfficer
    , SomeEnemyCard mrTrombly
    , SomeEnemyCard conspicuousStaff
    , SomeEnemyCard hotelGuest
    , --- Alien Interference
      SomeEnemyCard otherworldlyMeddler
    , --- Excelsior Management
      SomeEnemyCard hotelManager
    , SomeEnemyCard hotelSecurity
    , --- Dark Rituals
      SomeEnemyCard dimensionalShambler
    , SomeEnemyCard cultistOfTheEnclave
    , --- Sins of the Past
      SomeEnemyCard vengefulSpecter
    ]

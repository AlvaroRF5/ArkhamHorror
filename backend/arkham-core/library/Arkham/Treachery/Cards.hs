module Arkham.Treachery.Cards where

import Arkham.Prelude

import Arkham.Card.CardCode
import Arkham.Card.CardDef
import Arkham.Card.CardType
import Arkham.ClassSymbol
import Arkham.CommitRestriction
import Arkham.EncounterSet hiding (Byakhee, Dunwich, Poison)
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Keyword qualified as Keyword
import Arkham.Name
import Arkham.Trait hiding (Dreamlands)

baseTreachery
  :: CardCode
  -> Name
  -> Maybe (EncounterSet, Int)
  -> Maybe CardSubType
  -> CardDef
baseTreachery cardCode name mEncounterSet isWeakness =
  (emptyCardDef cardCode name (if isJust isWeakness then PlayerTreacheryType else TreacheryType))
    { cdCardSubType = isWeakness
    , cdClassSymbols = if isJust isWeakness then singleton Neutral else mempty
    , cdEncounterSet = fst <$> mEncounterSet
    , cdEncounterSetQuantity = snd <$> mEncounterSet
    , cdRevelation = IsRevelation
    }

surge :: CardDef -> CardDef
surge def = def {cdKeywords = insertSet Keyword.Surge (cdKeywords def)}

peril :: CardDef -> CardDef
peril def = def {cdKeywords = insertSet Keyword.Peril (cdKeywords def)}

weakness :: CardCode -> Name -> CardDef
weakness cardCode name = baseTreachery cardCode name Nothing (Just Weakness)

basicWeakness :: CardCode -> Name -> CardDef
basicWeakness cardCode name =
  baseTreachery cardCode name Nothing (Just BasicWeakness)

treachery :: CardCode -> Name -> EncounterSet -> Int -> CardDef
treachery cardCode name encounterSet encounterSetQuantity =
  baseTreachery
    cardCode
    name
    (Just (encounterSet, encounterSetQuantity))
    Nothing

allTreacheryCards :: Map CardCode CardDef
allTreacheryCards = allPlayerTreacheryCards <> allEncounterTreacheryCards

allPlayerTreacheryCards :: Map CardCode CardDef
allPlayerTreacheryCards =
  mapFromList
    $ concatMap
      toCardCodePairs
      [ abandonedAndAlone
      , accursedFate
      , acrossSpaceAndTime
      , amnesia
      , angeredSpirits
      , atychiphobia
      , bloodlust
      , boughtInBlood
      , callOfTheUnknown
      , calledByTheMists
      , caughtRedHanded
      , chronophobia
      , coverUp
      , crisisOfIdentity
      , curseOfTheRougarou
      , damned
      , darkFuture
      , detachedFromReality
      , doomed
      , drawingTheSign
      , finalRhapsody
      , finePrint
      , haunted
      , hospitalDebts
      , hypochondria
      , indebted
      , internalInjury
      , lostSoul
      , narcolepsy
      , nihilism
      , obsessive
      , offerYouCannotRefuse
      , outOfBodyExperience
      , overzealous
      , paranoia
      , poisoned
      , psychosis
      , rationalThought
      , rexsCurse
      , rookieMistake
      , searchingForIzzie
      , selfCentered
      , selfDestructive
      , sellYourSoul
      , shellShock
      , shockingDiscovery
      , smiteTheWicked
      , songOfTheMagahBird
      , starsOfHyades
      , terribleSecret
      , the13thVision
      , theBellTolls
      , theHarbinger
      , thePriceOfFailure
      , thriceDamnedCuriosity
      , throughTheGates
      , unspeakableOathBloodthirst
      , unspeakableOathCowardice
      , unspeakableOathCuriosity
      , voiceOfTheMessenger
      , whatHaveYouDone
      , wondrousLands
      , wrackedByNightmares
      , yaztaroth
      ]

allEncounterTreacheryCards :: Map CardCode CardDef
allEncounterTreacheryCards =
  mapFromList
    $ map
      (toCardCode &&& id)
      [ aTearInTime
      , aWorldInDarkness
      , abduction
      , acridMiasma
      , alteredBeast
      , ancestralFear
      , ancientEvils
      , ants
      , arcaneBarrier
      , arousingSuspicions
      , arrowsFromTheTrees
      , attractingAttention
      , baneOfTheLiving
      , bathophobia
      , beastOfTheBayou
      , bedeviled
      , beneathTheLodge
      , betweenWorlds
      , beyondTheVeil
      , blackStarsRise
      , bloodOnYourHands
      , brokenRails
      , burdensOfThePast
      , callToOrder
      , captiveMind
      , centuriesOfSecrets
      , chaosInTheWater
      , chaosManifest
      , childrenOfValusia
      , chillFromBelow
      , chillingPresence
      , clawsOfSteam
      , collapsingReality
      , conspiracyOfBlood
      , corrosion
      , crashingFloods
      , creepingDarkness
      , creepingPoison
      , cruelInterrogations
      , cryptChill
      , curseOfYig
      , cursedLuck
      , cursedSwamp
      , daemonicPiping
      , danceOfTheYellowKing
      , deadlyFate
      , deathApproaches
      , deepDark
      , deeperSlumber
      , descentIntoMadness
      , diabolicVoices
      , dismalCurse
      , disquietingDreams
      , dissonantVoices
      , draggedUnder
      , dreamersCurse
      , dreamlandsEclipse
      , dreamsOfRlyeh
      , drivenToMadness
      , eagerForDeath
      , eagerForDeathUnionAndDisillusion
      , encephalonSignal
      , entombed
      , ephemeralExhibits
      , evilPast
      , expulsion
      , extradimensionalVisions
      , eyesInTheWalls
      , falseLead
      , fateOfAllFools
      , finalMistake
      , fineDining
      , frozenInFear
      , frozenInFearAPhantomOfTruth
      , giftOfMadnessMisery
      , giftOfMadnessPity
      , ghostlyPresence
      , glimpseOfTheUnderworld
      , graspingHands
      , graveLight
      , graveLightSpectral
      , harvestedBrain
      , huntedByByakhee
      , huntedByCorsairs
      , huntedDown
      , huntingShadow
      , illOmen
      , incriminatingEvidence
      , insatiableBloodlust
      , kidnapped
      , lawOfYgirothChaos
      , lawOfYgirothDiscord
      , lawOfYgirothPandemonium
      , ledAstray
      , lightlessShadow
      , lightOfAforgomon
      , lockedDoor
      , lostHumanity
      , lostInTheWilds
      , lostInTheWoods
      , lostInTime
      , lostInVenice
      , lowOnSupplies
      , markOfTheOrder
      , markedByTheSign
      , markedForDeath
      , maskOfUmordhoth
      , maskedHorrors
      , massHysteria
      , meddlesomeFamiliar
      , mesmerize
      , morbidAwareness
      , mysteriesOfTheLodge
      , mysteriousChanting
      , nightTerrors
      , noTurningBack
      , nobodysHome
      , noxiousFumes
      , obscuringFog
      , offerOfPower
      , ominousPortents
      , onTheProwl
      , onWingsOfDarkness
      , oozeAndFilth
      , outbreak
      , overgrowth
      , passageIntoTheVeil
      , pitfall
      , poisonousSpores
      , possessionMurderous
      , possessionTorturous
      , possessionTraitorous
      , primordialGateway
      , prismaticPhenomenon
      , psychopompsSong
      , psychopompsSongUnionAndDisillusion
      , pulledByTheStars
      , punishment
      , pushedIntoTheBeyond
      , realmOfMadness
      , realmOfTorment
      , ripplesOnTheSurface
      , ritesHowled
      , rottingRemains
      , rottingRemainsBloodOnTheAltar
      , ruinAndDestruction
      , secretsOfTheBeyond
      , serpentsCall
      , serpentsIre
      , shadowSpawned
      , shadowed
      , shapesInTheMist
      , shatteredAges
      , sickeningWebs
      , slitheringBehindYou
      , snakeBite
      , snakescourge
      , somethingInTheDrinks
      , somniphobia
      , sordidAndSilent
      , spacesBetween
      , spectralMist
      , spiresOfCarcosa
      , spiritsTorment
      , stalkedInTheDark
      , straitjacket
      , strangeSigns
      , terrorInTheNight
      , terrorFromBeyond
      , terrorUnleashed
      , theCreaturesTracks
      , theCultsSearch
      , theEndIsNigh
      , theFinalAct
      , theKingsEdict
      , thePaleMaskBeckons
      , thePitBelow
      , theSecretMustBeKept
      , theShadowBehindYou
      , theYellowSign
      , theZealotsSeal
      , threadsOfReality
      , timelineDestabilization
      , toilAndTrouble
      , torturousChords
      , toughCrowd
      , toweringBeasts
      , trappedSpirits
      , twinSuns
      , twistOfFate
      , twistedToHisWill
      , ultimateChaos
      , umordhothsHunger
      , umordhothsWrath
      , unhallowedCountry
      , vastExpanse
      , vaultOfEarthlyDemise
      , violentOutburst
      , visionsOfFuturesPast
      , voiceOfTheJungle
      , vortexOfTime
      , wallsClosingIn
      , watchersGaze
      , watchersGazeUnionAndDisillusion
      , watchersGrasp
      , whisperedBargain
      , whispersInTheDark
      , whispersInYourHeadAnxiety
      , whispersInYourHeadDismay
      , whispersInYourHeadDoubt
      , whispersInYourHeadDread
      , whispersOfHypnos
      , willOfTheSpiderMother
      , windowToAnotherTime
      , wordsOfPower
      , worldsMerge
      , wormhole
      , wracked
      , wrackedByTime
      , yithianPresence
      , zoogBurrow
      ]

coverUp :: CardDef
coverUp =
  (weakness "01007" "Cover Up")
    { cdCardTraits = setFromList [Task]
    , cdAlternateCardCodes = ["01507"]
    }

hospitalDebts :: CardDef
hospitalDebts =
  (weakness "01011" "Hospital Debts")
    { cdCardTraits = setFromList [Task]
    , cdAlternateCardCodes = ["01511"]
    }

abandonedAndAlone :: CardDef
abandonedAndAlone =
  (weakness "01015" "Abandoned and Alone")
    { cdCardTraits = setFromList [Madness]
    , cdAlternateCardCodes = ["01515"]
    }

amnesia :: CardDef
amnesia =
  (basicWeakness "01096" "Amnesia")
    { cdCardTraits = setFromList [Madness]
    , cdAlternateCardCodes = ["01596"]
    }

paranoia :: CardDef
paranoia =
  (basicWeakness "01097" "Paranoia")
    { cdCardTraits = setFromList [Madness]
    , cdAlternateCardCodes = ["01597"]
    }

haunted :: CardDef
haunted =
  (basicWeakness "01098" "Haunted")
    { cdCardTraits = setFromList [Curse]
    , cdAlternateCardCodes = ["01598"]
    }

psychosis :: CardDef
psychosis =
  (basicWeakness "01099" "Psychosis")
    { cdCardTraits = setFromList [Madness]
    , cdAlternateCardCodes = ["01599"]
    }

hypochondria :: CardDef
hypochondria =
  (basicWeakness "01100" "Hypochondria")
    { cdCardTraits = setFromList [Madness]
    , cdAlternateCardCodes = ["01600"]
    }

huntingShadow :: CardDef
huntingShadow =
  (treachery "01135" "Hunting Shadow" TheMidnightMasks 3)
    { cdCardTraits = setFromList [Curse]
    , cdKeywords = setFromList [Keyword.Peril]
    }

falseLead :: CardDef
falseLead = treachery "01136" "False Lead" TheMidnightMasks 2

umordhothsWrath :: CardDef
umordhothsWrath =
  (treachery "01158" "Umôrdhoth's Wrath" TheDevourerBelow 2)
    { cdCardTraits = setFromList [Curse]
    }

graspingHands :: CardDef
graspingHands =
  (treachery "01162" "Grasping Hands" Ghouls 3)
    { cdCardTraits = setFromList [Hazard]
    }

rottingRemains :: CardDef
rottingRemains =
  (treachery "01163" "Rotting Remains" StrikingFear 3)
    { cdCardTraits = setFromList [Terror]
    }

frozenInFear :: CardDef
frozenInFear =
  (treachery "01164" "Frozen in Fear" StrikingFear 2)
    { cdCardTraits = setFromList [Terror]
    }

dissonantVoices :: CardDef
dissonantVoices =
  (treachery "01165" "Dissonant Voices" StrikingFear 2)
    { cdCardTraits = setFromList [Terror]
    }

ancientEvils :: CardDef
ancientEvils =
  (treachery "01166" "Ancient Evils" AncientEvils 3)
    { cdCardTraits = setFromList [Omen]
    }

cryptChill :: CardDef
cryptChill =
  (treachery "01167" "Crypt Chill" ChillingCold 2)
    { cdCardTraits = setFromList [Hazard]
    }

obscuringFog :: CardDef
obscuringFog =
  (treachery "01168" "Obscuring Fog" ChillingCold 2)
    { cdCardTraits = setFromList [Hazard]
    }

mysteriousChanting :: CardDef
mysteriousChanting =
  (treachery "01171" "Mysterious Chanting" DarkCult 2)
    { cdCardTraits = setFromList [Hex]
    }

onWingsOfDarkness :: CardDef
onWingsOfDarkness = treachery "01173" "On Wings of Darkness" Nightgaunts 2

lockedDoor :: CardDef
lockedDoor =
  (treachery "01174" "Locked Door" LockedDoors 2)
    { cdCardTraits = setFromList [Obstacle]
    }

theYellowSign :: CardDef
theYellowSign =
  (treachery "01176" "The Yellow Sign" AgentsOfHastur 2)
    { cdCardTraits = setFromList [Omen]
    }

offerOfPower :: CardDef
offerOfPower =
  (treachery "01178" "Offer of Power" AgentsOfYogSothoth 2)
    { cdCardTraits = setFromList [Pact]
    , cdKeywords = setFromList [Keyword.Peril]
    }

dreamsOfRlyeh :: CardDef
dreamsOfRlyeh =
  (treachery "01182" "Dreams of R'lyeh" AgentsOfCthulhu 2)
    { cdCardTraits = setFromList [Omen]
    }

smiteTheWicked :: CardDef
smiteTheWicked =
  (weakness "02007" "Smite the Wicked") {cdCardTraits = setFromList [Task]}

rexsCurse :: CardDef
rexsCurse =
  (weakness "02009" "Rex's Curse") {cdCardTraits = setFromList [Curse]}

searchingForIzzie :: CardDef
searchingForIzzie =
  (weakness "02011" "Searching for Izzie") {cdCardTraits = setFromList [Task]}

finalRhapsody :: CardDef
finalRhapsody =
  (weakness "02013" "Final Rhapsody") {cdCardTraits = setFromList [Endtimes]}

wrackedByNightmares :: CardDef
wrackedByNightmares =
  (weakness "02015" "Wracked by Nightmares")
    { cdCardTraits = setFromList [Madness]
    }

indebted :: CardDef
indebted =
  (basicWeakness "02037" "Indebted")
    { cdCardTraits = singleton Flaw
    , cdPermanent = True
    }

internalInjury :: CardDef
internalInjury =
  (basicWeakness "02038" "Internal Injury") {cdCardTraits = singleton Injury}

chronophobia :: CardDef
chronophobia =
  (basicWeakness "02039" "Chronophobia") {cdCardTraits = singleton Madness}

somethingInTheDrinks :: CardDef
somethingInTheDrinks =
  (treachery "02081" "Something in the Drinks" TheHouseAlwaysWins 2)
    { cdCardTraits = setFromList [Poison, Illicit]
    , cdKeywords = setFromList [Keyword.Surge]
    }

arousingSuspicions :: CardDef
arousingSuspicions =
  treachery "02082" "Arousing Suspicions" TheHouseAlwaysWins 2

visionsOfFuturesPast :: CardDef
visionsOfFuturesPast =
  (treachery "02083" "Visions of Futures Past" Sorcery 3)
    { cdCardTraits = setFromList [Hex]
    }

beyondTheVeil :: CardDef
beyondTheVeil =
  (treachery "02084" "Beyond the Veil" Sorcery 3)
    { cdCardTraits = setFromList [Hex]
    , cdKeywords = setFromList [Keyword.Surge]
    }

lightOfAforgomon :: CardDef
lightOfAforgomon =
  (treachery "02085" "Light of Aforgomon" BishopsThralls 2)
    { cdCardTraits = setFromList [Pact, Power]
    , cdKeywords = setFromList [Keyword.Peril]
    }

unhallowedCountry :: CardDef
unhallowedCountry =
  (treachery "02088" "Unhallowed Country" EncounterSet.Dunwich 2)
    { cdCardTraits = setFromList [Terror]
    }

sordidAndSilent :: CardDef
sordidAndSilent =
  ( treachery "02089" "Sordid and Silent" EncounterSet.Dunwich 2
  )
    { cdCardTraits = setFromList [Terror]
    }

eagerForDeath :: CardDef
eagerForDeath =
  (treachery "02091" "Eager for Death" Whippoorwills 2)
    { cdCardTraits = setFromList [Omen]
    }

cursedLuck :: CardDef
cursedLuck =
  (treachery "02092" "Cursed Luck" BadLuck 3)
    { cdCardTraits = setFromList [Omen]
    }

twistOfFate :: CardDef
twistOfFate =
  (treachery "02093" "Twist of Fate" BadLuck 3)
    { cdCardTraits = setFromList [Omen]
    }

alteredBeast :: CardDef
alteredBeast =
  (treachery "02096" "Altered Beast" BeastThralls 2)
    { cdCardTraits = setFromList [Power]
    }

huntedDown :: CardDef
huntedDown =
  (treachery "02099" "Hunted Down" NaomisCrew 2)
    { cdCardTraits = setFromList [Tactic]
    }

pushedIntoTheBeyond :: CardDef
pushedIntoTheBeyond =
  (treachery "02100" "Pushed into the Beyond" TheBeyond 2)
    { cdCardTraits = setFromList [Hex]
    }

terrorFromBeyond :: CardDef
terrorFromBeyond =
  (treachery "02101" "Terror from Beyond" TheBeyond 2)
    { cdCardTraits = setFromList [Hex, Terror]
    , cdKeywords = setFromList [Keyword.Peril]
    }

arcaneBarrier :: CardDef
arcaneBarrier =
  (treachery "02102" "Arcane Barrier" TheBeyond 2)
    { cdCardTraits = setFromList [Hex, Obstacle]
    }

shadowSpawned :: CardDef
shadowSpawned =
  (treachery "02142" "Shadow-spawned" TheMiskatonicMuseum 1)
    { cdCardTraits = singleton Power
    }

stalkedInTheDark :: CardDef
stalkedInTheDark =
  (treachery "02143" "Stalked in the Dark" TheMiskatonicMuseum 2)
    { cdCardTraits = singleton Tactic
    }

passageIntoTheVeil :: CardDef
passageIntoTheVeil =
  (treachery "02144" "Passage into the Veil" TheMiskatonicMuseum 3)
    { cdCardTraits = singleton Power
    }

ephemeralExhibits :: CardDef
ephemeralExhibits =
  (treachery "02145" "Ephemeral Exhibits" TheMiskatonicMuseum 2)
    { cdCardTraits = singleton Terror
    }

slitheringBehindYou :: CardDef
slitheringBehindYou =
  treachery "02146" "Slithering Behind You" TheMiskatonicMuseum 2

acrossSpaceAndTime :: CardDef
acrossSpaceAndTime =
  (weakness "02178" "Across Space and Time")
    { cdCardTraits = setFromList [Madness]
    , cdEncounterSet = Just TheEssexCountyExpress
    , cdEncounterSetQuantity = Just 4
    }

clawsOfSteam :: CardDef
clawsOfSteam =
  (treachery "02180" "Claws of Steam" TheEssexCountyExpress 3)
    { cdCardTraits = singleton Power
    }

brokenRails :: CardDef
brokenRails =
  (treachery "02181" "Broken Rails" TheEssexCountyExpress 3)
    { cdCardTraits = singleton Hazard
    }

kidnapped :: CardDef
kidnapped = treachery "02220" "Kidnapped!" BloodOnTheAltar 3

psychopompsSong :: CardDef
psychopompsSong =
  (treachery "02221" "Psychopomp's Song" BloodOnTheAltar 2)
    { cdCardTraits = singleton Omen
    , cdKeywords = setFromList [Keyword.Surge, Keyword.Peril]
    }

strangeSigns :: CardDef
strangeSigns =
  (treachery "02222" "Strange Signs" BloodOnTheAltar 2)
    { cdCardTraits = singleton Omen
    }

rottingRemainsBloodOnTheAltar :: CardDef
rottingRemainsBloodOnTheAltar =
  (treachery "02223" "Rotting Remains" BloodOnTheAltar 3)
    { cdCardTraits = singleton Terror
    }

toweringBeasts :: CardDef
toweringBeasts =
  (treachery "02256" "Towering Beasts" UndimensionedAndUnseen 4)
    { cdKeywords = singleton Keyword.Peril
    }

ruinAndDestruction :: CardDef
ruinAndDestruction =
  (treachery "02257" "Ruin and Destruction" UndimensionedAndUnseen 3)
    { cdCardTraits = singleton Hazard
    }

attractingAttention :: CardDef
attractingAttention =
  (treachery "02258" "Attracting Attention" UndimensionedAndUnseen 2)
    { cdKeywords = singleton Keyword.Surge
    }

theCreaturesTracks :: CardDef
theCreaturesTracks =
  (treachery "02259" "The Creatures' Tracks" UndimensionedAndUnseen 2)
    { cdCardTraits = singleton Terror
    , cdKeywords = singleton Keyword.Peril
    }

ritesHowled :: CardDef
ritesHowled =
  (treachery "02296" "Rites Howled" WhereDoomAwaits 3)
    { cdCardTraits = singleton Hex
    }

spacesBetween :: CardDef
spacesBetween =
  (treachery "02297" "Spaces Between" WhereDoomAwaits 3)
    { cdCardTraits = setFromList [Hex, Hazard]
    }

vortexOfTime :: CardDef
vortexOfTime =
  (treachery "02298" "Vortex of Time" WhereDoomAwaits 3)
    { cdCardTraits = setFromList [Hex, Hazard]
    }

collapsingReality :: CardDef
collapsingReality =
  (treachery "02331" "Collapsing Reality" LostInTimeAndSpace 3)
    { cdCardTraits = setFromList [Hazard]
    }

wormhole :: CardDef
wormhole =
  (treachery "02332" "Wormhole" LostInTimeAndSpace 2)
    { cdCardTraits = setFromList [Hazard]
    }

vastExpanse :: CardDef
vastExpanse =
  (treachery "02333" "Vast Expanse" LostInTimeAndSpace 3)
    { cdCardTraits = setFromList [Terror]
    }

shellShock :: CardDef
shellShock =
  (weakness "03008" "Shell Shock") {cdCardTraits = setFromList [Flaw]}

starsOfHyades :: CardDef
starsOfHyades =
  (weakness "03013" "Stars of Hyades") {cdCardTraits = setFromList [Curse]}

angeredSpirits :: CardDef
angeredSpirits =
  (weakness "03015" "Angered Spirits") {cdCardTraits = singleton Task}

crisisOfIdentity :: CardDef
crisisOfIdentity =
  (weakness "03019" "Crisis of Identity") {cdCardTraits = singleton Madness}

overzealous :: CardDef
overzealous =
  (basicWeakness "03040" "Overzealous") {cdCardTraits = singleton Flaw}

drawingTheSign :: CardDef
drawingTheSign =
  (basicWeakness "03041" "Drawing the Sign")
    { cdCardTraits = setFromList [Pact, Madness]
    }

fineDining :: CardDef
fineDining =
  (treachery "03082" "Fine Dining" TheLastKing 2)
    { cdCardTraits = singleton Terror
    , cdKeywords = singleton Keyword.Peril
    }

toughCrowd :: CardDef
toughCrowd =
  (treachery "03083" "Tough Crowd" TheLastKing 2)
    { cdCardTraits = singleton Hazard
    }

whispersInYourHeadDismay :: CardDef
whispersInYourHeadDismay =
  (treachery "03084a" ("Whispers in Your Head" <:> "Dismay") Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

whispersInYourHeadDread :: CardDef
whispersInYourHeadDread =
  (treachery "03084b" ("Whispers in Your Head" <:> "Dread") Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

whispersInYourHeadAnxiety :: CardDef
whispersInYourHeadAnxiety =
  (treachery "03084c" ("Whispers in Your Head" <:> "Anxiety") Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

whispersInYourHeadDoubt :: CardDef
whispersInYourHeadDoubt =
  (treachery "03084d" ("Whispers in Your Head" <:> "Doubt") Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

descentIntoMadness :: CardDef
descentIntoMadness =
  (treachery "03085" "Descent into Madness" Delusions 2)
    { cdCardTraits = singleton Terror
    , cdKeywords = singleton Keyword.Surge
    }

huntedByByakhee :: CardDef
huntedByByakhee =
  ( treachery "03087" "Hunted by Byakhee" EncounterSet.Byakhee 2
  )
    { cdCardTraits = singleton Pact
    }

blackStarsRise :: CardDef
blackStarsRise =
  (treachery "03090" "Black Stars Rise" EvilPortents 2)
    { cdCardTraits = singleton Omen
    }

spiresOfCarcosa :: CardDef
spiresOfCarcosa =
  (treachery "03091" "Spires of Carcosa" EvilPortents 2)
    { cdCardTraits = singleton Omen
    }

twistedToHisWill :: CardDef
twistedToHisWill =
  (treachery "03092" "Twisted to His Will" EvilPortents 2)
    { cdCardTraits = singleton Pact
    }

spiritsTorment :: CardDef
spiritsTorment =
  (treachery "03094" "Spirit's Torment" Hauntings 2)
    { cdCardTraits = setFromList [Curse, Geist]
    }

danceOfTheYellowKing :: CardDef
danceOfTheYellowKing =
  (treachery "03097" "Dance of the Yellow King" HastursGift 2)
    { cdCardTraits = singleton Pact
    }

theKingsEdict :: CardDef
theKingsEdict =
  (treachery "03100" "The King's Edict" CultOfTheYellowSign 2)
    { cdCardTraits = singleton Pact
    }

oozeAndFilth :: CardDef
oozeAndFilth =
  (treachery "03101" "Ooze and Filth" DecayAndFilth 2)
    { cdCardTraits = singleton Hazard
    }

corrosion :: CardDef
corrosion =
  (treachery "03102" "Corrosion" DecayAndFilth 2)
    { cdCardTraits = singleton Hazard
    }

markedByTheSign :: CardDef
markedByTheSign =
  (treachery "03104" "Marked by the Sign" TheStranger 2)
    { cdCardTraits = singleton Pact
    , cdKeywords = singleton Keyword.Peril
    }

thePaleMaskBeckons :: CardDef
thePaleMaskBeckons =
  (treachery "03105" "The Pale Mask Beckons" TheStranger 1)
    { cdCardTraits = setFromList [Omen, Pact]
    }

ledAstray :: CardDef
ledAstray =
  (treachery "03145" "Led Astray" EchoesOfThePast 3)
    { cdCardTraits = singleton Scheme
    , cdKeywords = singleton Keyword.Peril
    }

theCultsSearch :: CardDef
theCultsSearch =
  (treachery "03146" "The Cult's Search" EchoesOfThePast 2)
    { cdCardTraits = singleton Scheme
    }

straitjacket :: CardDef
straitjacket =
  (treachery "03185" "Straitjacket" TheUnspeakableOath 2)
    { cdCardTraits = setFromList [Item, Clothing]
    }

giftOfMadnessPity :: CardDef
giftOfMadnessPity =
  (treachery "03186" ("Gift of Madness" <:> "Pity") TheUnspeakableOath 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

giftOfMadnessMisery :: CardDef
giftOfMadnessMisery =
  (treachery "03187" ("Gift of Madness" <:> "Misery") TheUnspeakableOath 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

wallsClosingIn :: CardDef
wallsClosingIn =
  (treachery "03188" "Walls Closing In" TheUnspeakableOath 3)
    { cdCardTraits = singleton Terror
    }

twinSuns :: CardDef
twinSuns =
  (treachery "03223" "Twin Suns" APhantomOfTruth 2)
    { cdCardTraits = singleton Omen
    }

deadlyFate :: CardDef
deadlyFate =
  (treachery "03224" "Deadly Fate" APhantomOfTruth 3)
    { cdCardTraits = singleton Omen
    }

torturousChords :: CardDef
torturousChords =
  (treachery "03225" "Torturous Chords" APhantomOfTruth 3)
    { cdCardTraits = setFromList [Hex, Terror]
    }

frozenInFearAPhantomOfTruth :: CardDef
frozenInFearAPhantomOfTruth =
  (treachery "03226" "Frozen in Fear" APhantomOfTruth 2)
    { cdCardTraits = singleton Terror
    }

lostSoul :: CardDef
lostSoul =
  (weakness "03227" "Lost Soul")
    { cdCardTraits = setFromList [Madness, Pact]
    , cdEncounterSet = Just APhantomOfTruth
    , cdEncounterSetQuantity = Just 4
    }

eyesInTheWalls :: CardDef
eyesInTheWalls =
  (treachery "03260" "Eyes in the Walls" ThePallidMask 3)
    { cdCardTraits = singleton Terror
    }

theShadowBehindYou :: CardDef
theShadowBehindYou =
  ( treachery "03261" "The Shadow Behind You" ThePallidMask 3
  )
    { cdCardTraits = singleton Terror
    }

thePitBelow :: CardDef
thePitBelow =
  (treachery "03262" "The Pit Below" ThePallidMask 3)
    { cdCardTraits = singleton Hazard
    }

crashingFloods :: CardDef
crashingFloods =
  (treachery "03302" "Crashing Floods" BlackStarsRise 3)
    { cdCardTraits = singleton Omen
    }

worldsMerge :: CardDef
worldsMerge =
  (treachery "03303" "Worlds Merge" BlackStarsRise 3)
    { cdCardTraits = singleton Omen
    }

dismalCurse :: CardDef
dismalCurse =
  (treachery "03337" "Dismal Curse" DimCarcosa 3)
    { cdCardTraits = setFromList [Curse, Terror]
    }

realmOfMadness :: CardDef
realmOfMadness =
  (treachery "03338" "Realm of Madness" DimCarcosa 2)
    { cdCardTraits = singleton Terror
    }

theFinalAct :: CardDef
theFinalAct =
  (treachery "03339" "The Final Act" DimCarcosa 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Surge]
    }

possessionTraitorous :: CardDef
possessionTraitorous =
  (treachery "03340" ("Possession" <:> "Traitorous") DimCarcosa 1)
    { cdCardTraits = setFromList [Hex, Terror]
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    , cdCommitRestrictions = [CommittableTreachery]
    }

possessionTorturous :: CardDef
possessionTorturous =
  (treachery "03341" ("Possession" <:> "Torturous") DimCarcosa 1)
    { cdCardTraits = setFromList [Hex, Terror]
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

possessionMurderous :: CardDef
possessionMurderous =
  (treachery "03342" ("Possession" <:> "Murderous") DimCarcosa 1)
    { cdCardTraits = setFromList [Hex, Terror]
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdCardInHandEffects = True
    }

boughtInBlood :: CardDef
boughtInBlood =
  (weakness "04007" "Bought in Blood") {cdCardTraits = singleton Flaw}

callOfTheUnknown :: CardDef
callOfTheUnknown =
  (weakness "04009" "Call of the Unknown") {cdCardTraits = singleton Task}

caughtRedHanded :: CardDef
caughtRedHanded =
  (weakness "04012" "Caught Red-Handed") {cdCardTraits = singleton Blunder}

voiceOfTheMessenger :: CardDef
voiceOfTheMessenger =
  (weakness "04016" "Voice of the Messenger")
    { cdCardTraits = setFromList [Curse, Pact]
    }

thePriceOfFailure :: CardDef
thePriceOfFailure =
  (weakness "04039" "The Price of Failure") {cdCardTraits = singleton Pact}

doomed :: CardDef
doomed =
  (basicWeakness "04040" "Doomed")
    { cdCardTraits = singleton Curse
    , cdDeckRestrictions = [CampaignModeOnly]
    }

accursedFate :: CardDef
accursedFate =
  (weakness "04041" "Accursed Fate") {cdCardTraits = singleton Curse}

theBellTolls :: CardDef
theBellTolls =
  (weakness "04042" "The Bell Tolls") {cdCardTraits = singleton Curse}

overgrowth :: CardDef
overgrowth =
  (treachery "04076" "Overgrowth" Rainforest 2)
    { cdCardTraits = singleton Obstacle
    }

voiceOfTheJungle :: CardDef
voiceOfTheJungle =
  (treachery "04077" "Voice of the Jungle" Rainforest 2)
    { cdCardTraits = singleton Power
    }

snakeBite :: CardDef
snakeBite =
  (treachery "04080" "Snake Bite" Serpents 3)
    { cdCardTraits = setFromList [Hazard, Poison]
    }

lostInTheWilds :: CardDef
lostInTheWilds =
  (treachery "04081" "Lost in the Wilds" Expedition 3)
    { cdCardTraits = singleton Blunder
    }

lowOnSupplies :: CardDef
lowOnSupplies =
  (treachery "04082" "Low on Supplies" Expedition 2)
    { cdCardTraits = singleton Blunder
    , cdKeywords = singleton Keyword.Peril
    }

curseOfYig :: CardDef
curseOfYig =
  (treachery "04085" "Curse of Yig" AgentsOfYig 2)
    { cdCardTraits = singleton Curse
    }

arrowsFromTheTrees :: CardDef
arrowsFromTheTrees =
  (treachery "04087" "Arrows from the Trees" GuardiansOfTime 2)
    { cdCardTraits = singleton Scheme
    }

finalMistake :: CardDef
finalMistake =
  (treachery "04088" "Final Mistake" DeadlyTraps 3)
    { cdCardTraits = singleton Trap
    }

entombed :: CardDef
entombed =
  (treachery "04089" "Entombed" DeadlyTraps 2)
    { cdCardTraits = singleton Trap
    }

aTearInTime :: CardDef
aTearInTime =
  (treachery "04090" "A Tear in Time" TemporalFlux 3)
    { cdCardTraits = singleton Hex
    }

lostInTime :: CardDef
lostInTime =
  (treachery "04091" "Lost in Time" TemporalFlux 2)
    { cdCardTraits = singleton Hex
    }

illOmen :: CardDef
illOmen =
  (treachery "04092" "Ill Omen" ForgottenRuins 2)
    { cdCardTraits = setFromList [Omen, Terror]
    , cdKeywords = singleton Keyword.Peril
    }

ancestralFear :: CardDef
ancestralFear =
  (treachery "04093" "Ancestral Fear" ForgottenRuins 2)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Surge]
    , cdVengeancePoints = Just 1
    }

deepDark :: CardDef
deepDark =
  (treachery "04094" "Deep Dark" ForgottenRuins 3)
    { cdCardTraits = singleton Hazard
    }

shadowed :: CardDef
shadowed =
  (treachery "04096" "Shadowed" PnakoticBrotherhood 2)
    { cdCardTraits = singleton Scheme
    }

wordsOfPower :: CardDef
wordsOfPower =
  (treachery "04097" "Words of Power" PnakoticBrotherhood 2)
    { cdCardTraits = singleton Hex
    }

snakescourge :: CardDef
snakescourge =
  (treachery "04099" "Snakescourge" YigsVenom 2)
    { cdCardTraits = singleton Curse
    }

serpentsCall :: CardDef
serpentsCall =
  (treachery "04100" "Serpent's Call" YigsVenom 1)
    { cdCardTraits = singleton Power
    }

creepingPoison :: CardDef
creepingPoison =
  (treachery "04101" "Creeping Poison" EncounterSet.Poison 2)
    { cdCardTraits = singleton Poison
    , cdKeywords = singleton Keyword.Surge
    }

poisoned :: CardDef
poisoned =
  (weakness "04102" "Poisoned")
    { cdCardTraits = singleton Poison
    , cdPermanent = True
    , cdEncounterSet = Just EncounterSet.Poison
    , cdEncounterSetQuantity = Just 4
    }

theSecretMustBeKept :: CardDef
theSecretMustBeKept =
  (treachery "04144" "The Secret Must Be Kept" EncounterSet.ThreadsOfFate 3)
    { cdCardTraits = singleton Scheme
    , cdKeywords = singleton Keyword.Peril
    }

nobodysHome :: CardDef
nobodysHome =
  (treachery "04145" "Nobody's Home" EncounterSet.ThreadsOfFate 2)
    { cdCardTraits = singleton Mystery
    }

conspiracyOfBlood :: CardDef
conspiracyOfBlood =
  (treachery "04146" "Conspiracy of Blood" EncounterSet.ThreadsOfFate 2)
    { cdCardTraits = singleton Hex
    }

windowToAnotherTime :: CardDef
windowToAnotherTime =
  (treachery "04189" "Window to Another Time" EncounterSet.TheBoundaryBeyond 3)
    { cdCardTraits = singleton Hex
    , cdKeywords = singleton Keyword.Peril
    }

timelineDestabilization :: CardDef
timelineDestabilization =
  (treachery "04190" "Timeline Destabilization" EncounterSet.TheBoundaryBeyond 3)
    { cdCardTraits = singleton Hex
    }

pitfall :: CardDef
pitfall =
  (treachery "04215" "Pitfall" EncounterSet.HeartOfTheElders 3)
    { cdCardTraits = singleton Trap
    , cdKeywords = singleton Keyword.Peril
    }

poisonousSpores :: CardDef
poisonousSpores =
  (treachery "04216" "Poisonous Spores" EncounterSet.HeartOfTheElders 3)
    { cdCardTraits = singleton Hazard
    }

ants :: CardDef
ants =
  (treachery "04221" "Ants!" EncounterSet.PillarsOfJudgement 3)
    { cdCardTraits = singleton Hazard
    }

noTurningBack :: CardDef
noTurningBack =
  (treachery "04228" "No Turning Back" EncounterSet.KnYan 3)
    { cdCardTraits = singleton Hazard
    }

yithianPresence :: CardDef
yithianPresence =
  (treachery "04260" "Yithian Presence" EncounterSet.TheCityOfArchives 3)
    { cdCardTraits = setFromList [Power, Terror]
    }

cruelInterrogations :: CardDef
cruelInterrogations =
  (treachery "04261" "Cruel Interrogations" EncounterSet.TheCityOfArchives 3)
    { cdCardTraits = setFromList [Injury, Terror]
    }

lostHumanity :: CardDef
lostHumanity =
  (treachery "04262" "Lost Humanity" EncounterSet.TheCityOfArchives 2)
    { cdCardTraits = singleton Terror
    }

captiveMind :: CardDef
captiveMind =
  (treachery "04263" "Captive Mind" EncounterSet.TheCityOfArchives 2)
    { cdCardTraits = singleton Hex
    }

outOfBodyExperience :: CardDef
outOfBodyExperience =
  (weakness "04264" "Out of Body Experience")
    { cdCardTraits = setFromList [Madness, Paradox]
    , cdEncounterSet = Just TheCityOfArchives
    , cdEncounterSetQuantity = Just 4
    }

childrenOfValusia :: CardDef
childrenOfValusia =
  (treachery "04299" "Children of Valusia" TheDepthsOfYoth 3)
    { cdCardTraits = singleton Scheme
    }

lightlessShadow :: CardDef
lightlessShadow =
  (treachery "04300" "Lightless Shadow" TheDepthsOfYoth 3)
    { cdCardTraits = singleton Terror
    }

bathophobia :: CardDef
bathophobia =
  (treachery "04301" "Bathophobia" TheDepthsOfYoth 3)
    { cdCardTraits = singleton Terror
    }

serpentsIre :: CardDef
serpentsIre =
  (treachery "04302" "Serpent's Ire" TheDepthsOfYoth 2)
    { cdCardTraits = singleton Scheme
    }

shatteredAges :: CardDef
shatteredAges =
  (treachery "04339" "Shattered Ages" ShatteredAeons 2)
    { cdCardTraits = singleton Hex
    }

betweenWorlds :: CardDef
betweenWorlds =
  (treachery "04340" "Between Worlds" ShatteredAeons 2)
    { cdCardTraits = singleton Hex
    }

wrackedByTime :: CardDef
wrackedByTime =
  (treachery "04341" "Wracked by Time" ShatteredAeons 3)
    { cdCardTraits = singleton Hex
    }

creepingDarkness :: CardDef
creepingDarkness =
  (treachery "04342" "Creeping Darkness" ShatteredAeons 2)
    { cdCardTraits = singleton Hazard
    }

rationalThought :: CardDef
rationalThought =
  (weakness "05008" "Rational Thought")
    { cdCardTraits = singleton Flaw
    }

terribleSecret :: CardDef
terribleSecret =
  (weakness "05015" "Terrible Secret")
    { cdCardTraits = singleton Madness
    , cdRevelation = CannotBeCanceledRevelation
    }

the13thVision :: CardDef
the13thVision =
  (basicWeakness "05041" "The 13th Vision")
    { cdCardTraits = singleton Omen
    }

watchersGrasp :: CardDef
watchersGrasp =
  (treachery "05087" "Watcher's Grasp" TheWatcher 2)
    { cdCardTraits = setFromList [Power, Spectral]
    }

daemonicPiping :: CardDef
daemonicPiping =
  surge
    $ (treachery "05089" "Daemonic Piping" AgentsOfAzathoth 3)
      { cdCardTraits = setFromList [Power, Terror]
      }

diabolicVoices :: CardDef
diabolicVoices =
  (treachery "05092" "Diabolic Voices" Witchcraft 3)
    { cdCardTraits = singleton Curse
    }

wracked :: CardDef
wracked =
  (treachery "05093" "Wracked" Witchcraft 2)
    { cdCardTraits = singleton Hex
    }

bedeviled :: CardDef
bedeviled =
  (treachery "05094" "Bedeviled" Witchcraft 2)
    { cdCardTraits = singleton Hex
    }

mysteriesOfTheLodge :: CardDef
mysteriesOfTheLodge =
  (treachery "05097" "Mysteries of the Lodge" SilverTwilightLodge 2)
    { cdCardTraits = singleton Scheme
    }

evilPast :: CardDef
evilPast =
  (treachery "05098" "Evil Past" CityOfSins 2)
    { cdCardTraits = singleton Curse
    }

centuriesOfSecrets :: CardDef
centuriesOfSecrets =
  (treachery "05099" "Centuries of Secrets" CityOfSins 3)
    { cdCardTraits = singleton Curse
    }

whispersInTheDark :: CardDef
whispersInTheDark =
  (treachery "05102" "Whispers in the Dark" SpectralPredators 2)
    { cdCardTraits = setFromList [Omen, Spectral]
    }

trappedSpirits :: CardDef
trappedSpirits =
  (treachery "05104" "Trapped Spirits" TrappedSpirits 2)
    { cdCardTraits = setFromList [Terror, Spectral]
    }

realmOfTorment :: CardDef
realmOfTorment =
  (treachery "05105" "Realm of Torment" RealmOfDeath 2)
    { cdCardTraits = setFromList [Terror, Spectral]
    }

shapesInTheMist :: CardDef
shapesInTheMist =
  surge
    $ (treachery "05106" "Shapes in the Mist" RealmOfDeath 2)
      { cdCardTraits = setFromList [Terror, Spectral]
      }

terrorInTheNight :: CardDef
terrorInTheNight =
  (treachery "05107" "Terror in the Night" InexorableFate 3)
    { cdCardTraits = setFromList [Terror, Spectral]
    }

fateOfAllFools :: CardDef
fateOfAllFools =
  (treachery "05108" "Fate of All Fools" InexorableFate 3)
    { cdCardTraits = setFromList [Omen, Spectral]
    , cdKeywords = singleton Keyword.Peril
    }

meddlesomeFamiliar :: CardDef
meddlesomeFamiliar =
  (treachery "05143" "Meddlesome Familiar" TheSecretName 3)
    { cdCardTraits = singleton Curse
    }

ghostlyPresence :: CardDef
ghostlyPresence =
  (treachery "05144" "Ghostly Presence" TheSecretName 2)
    { cdCardTraits = singleton Omen
    }

extradimensionalVisions :: CardDef
extradimensionalVisions =
  (treachery "05145" "Extradimensional Visions" TheSecretName 2)
    { cdCardTraits = singleton Hex
    }

pulledByTheStars :: CardDef
pulledByTheStars =
  (treachery "05146" "Pulled by the Stars" TheSecretName 2)
    { cdCardTraits = singleton Hex
    }

disquietingDreams :: CardDef
disquietingDreams =
  (treachery "05147" "Disquieting Dreams" TheSecretName 2)
    { cdCardTraits = singleton Terror
    }

punishment :: CardDef
punishment =
  (treachery "05181" "Punishment" TheWagesOfSin 2)
    { cdCardTraits = singleton Hex
    }

burdensOfThePast :: CardDef
burdensOfThePast =
  (treachery "05182" "Burdens of the Past" TheWagesOfSin 2)
    { cdCardTraits = setFromList [Curse, Spectral]
    }

ominousPortents :: CardDef
ominousPortents =
  (treachery "05183" "Ominous Portents" TheWagesOfSin 2)
    { cdCardTraits = singleton Omen
    , cdKeywords = singleton Keyword.Peril
    }

graveLight :: CardDef
graveLight =
  (treachery "05184" "Grave-Light" TheWagesOfSin 2)
    { cdCardTraits = singleton Curse
    }

-- Gravelight is the only card that cares which encounter deck it is drawn
-- from, so instead we represent it as two cards for which deck it is in.
graveLightSpectral :: CardDef
graveLightSpectral =
  (treachery "x05184" "Grave-Light" TheWagesOfSin 0)
    { cdCardTraits = singleton Curse
    , cdArt = "05184"
    }

baneOfTheLiving :: CardDef
baneOfTheLiving =
  (treachery "05185" "Bane of the Living" TheWagesOfSin 2)
    { cdCardTraits = setFromList [Curse, Spectral]
    , cdKeywords = singleton Keyword.Peril
    }

callToOrder :: CardDef
callToOrder =
  (treachery "05223" "Call to Order" ForTheGreaterGood 2)
    { cdCardTraits = singleton Scheme
    }

expulsion :: CardDef
expulsion =
  (treachery "05224" "Expulsion" ForTheGreaterGood 2)
    { cdCardTraits = singleton Scheme
    }

beneathTheLodge :: CardDef
beneathTheLodge =
  (treachery "05225" "Beneath the Lodge" ForTheGreaterGood 2)
    { cdCardTraits = singleton Scheme
    }

markOfTheOrder :: CardDef
markOfTheOrder =
  (treachery "05226" "Mark of the Order" ForTheGreaterGood 2)
    { cdCardTraits = singleton Scheme
    , cdKeywords = singleton Keyword.Surge
    }

eagerForDeathUnionAndDisillusion :: CardDef
eagerForDeathUnionAndDisillusion =
  (treachery "05268" "Eager for Death" UnionAndDisillusion 2)
    { cdCardTraits = setFromList [Omen]
    }

psychopompsSongUnionAndDisillusion :: CardDef
psychopompsSongUnionAndDisillusion =
  (treachery "05269" "Psychopomp's Song" UnionAndDisillusion 2)
    { cdCardTraits = singleton Omen
    , cdKeywords = setFromList [Keyword.Surge, Keyword.Peril]
    }

deathApproaches :: CardDef
deathApproaches =
  (treachery "05270" "Death Approaches" UnionAndDisillusion 2)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Surge, Keyword.Peril]
    }

markedForDeath :: CardDef
markedForDeath =
  (treachery "05271" "Marked for Death" UnionAndDisillusion 2)
    { cdCardTraits = singleton Curse
    }

watchersGazeUnionAndDisillusion :: CardDef
watchersGazeUnionAndDisillusion =
  (treachery "05272" "Watcher's Gaze" UnionAndDisillusion 1)
    { cdCardTraits = singleton Curse
    }

chaosManifest :: CardDef
chaosManifest =
  (treachery "05306" "Chaos Manifest" InTheClutchesOfChaos 3)
    { cdCardTraits = singleton Power
    }

primordialGateway :: CardDef
primordialGateway =
  (treachery "05307" "Primordial Gateway" InTheClutchesOfChaos 2)
    { cdCardTraits = singleton Power
    }

terrorUnleashed :: CardDef
terrorUnleashed =
  (treachery "05308" "Terror Unleashed" InTheClutchesOfChaos 3)
    { cdCardTraits = singleton Curse
    }

secretsOfTheBeyond :: CardDef
secretsOfTheBeyond =
  (treachery "05310" "Secrets of the Beyond" SecretsOfTheUniverse 2)
    { cdCardTraits = singleton Hex
    }

toilAndTrouble :: CardDef
toilAndTrouble =
  (treachery "05312" "Toil and Trouble" MusicOfTheDamned 2)
    { cdCardTraits = singleton Hex
    , cdKeywords = singleton Keyword.Peril
    }

ultimateChaos :: CardDef
ultimateChaos =
  (treachery "05342" "Ultimate Chaos" BeforeTheBlackThrone 3)
    { cdCardTraits = singleton Power
    , cdRevelation = CannotBeCanceledRevelation
    }

whisperedBargain :: CardDef
whisperedBargain =
  (treachery "05343" "Whispered Bargain" BeforeTheBlackThrone 2)
    { cdCardTraits = singleton Pact
    , cdKeywords = singleton Keyword.Peril
    }

theEndIsNigh :: CardDef
theEndIsNigh =
  (treachery "05344" "The End is Nigh!" BeforeTheBlackThrone 2)
    { cdCardTraits = singleton Endtimes
    }

aWorldInDarkness :: CardDef
aWorldInDarkness =
  (treachery "05345" "A World in Darkness" BeforeTheBlackThrone 2)
    { cdCardTraits = singleton Endtimes
    }

rookieMistake :: CardDef
rookieMistake =
  (weakness "06007" "Rookie Mistake")
    { cdCardTraits = setFromList [Blunder, Flaw]
    }

shockingDiscovery :: CardDef
shockingDiscovery =
  (weakness "06009" "Shocking Discovery")
    { cdCardTraits = setFromList [Blunder, Mystery]
    , cdCardInSearchEffects = True
    }

detachedFromReality :: CardDef
detachedFromReality =
  (weakness "06014" "Detached from Reality")
    { cdCardTraits = setFromList [Madness]
    }

bloodlust :: CardDef
bloodlust =
  (weakness "06019" "Bloodlust")
    { cdCardTraits = setFromList [Madness]
    , cdKeywords = singleton (Keyword.Bonded 3 "06018")
    }

selfCentered :: CardDef
selfCentered =
  (basicWeakness "06035" "Self-Centered")
    { cdCardTraits = setFromList [Flaw]
    , cdDeckRestrictions = [MultiplayerOnly]
    }

narcolepsy :: CardDef
narcolepsy =
  (basicWeakness "06037" "Narcolepsy")
    { cdCardTraits = setFromList [Madness]
    , cdDeckRestrictions = [MultiplayerOnly]
    }

lostInTheWoods :: CardDef
lostInTheWoods =
  (treachery "06062" "Lost in the Woods" BeyondTheGatesOfSleep 2)
    { cdCardTraits = singleton Blunder
    , cdKeywords = singleton Keyword.Surge
    }

outbreak :: CardDef
outbreak =
  (treachery "06083" "Outbreak" WakingNightmare 3)
    { cdCardTraits = singleton Hazard
    }

willOfTheSpiderMother :: CardDef
willOfTheSpiderMother =
  (treachery "06085" "Will of the Spider-Mother" AgentsOfAtlachNacha 2)
    { cdCardTraits = singleton Power
    }

lawOfYgirothChaos :: CardDef
lawOfYgirothChaos =
  (treachery "06087" ("Law of 'Ygiroth" <:> "Chaos") AgentsOfNyarlathotep 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

lawOfYgirothDiscord :: CardDef
lawOfYgirothDiscord =
  (treachery "06088" ("Law of 'Ygiroth" <:> "Discord") AgentsOfNyarlathotep 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

lawOfYgirothPandemonium :: CardDef
lawOfYgirothPandemonium =
  (treachery "06089" ("Law of 'Ygiroth" <:> "Pandemonium") AgentsOfNyarlathotep 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

whispersOfHypnos :: CardDef
whispersOfHypnos =
  (treachery "06090" "Whispers of Hypnos" WhispersOfHypnos 3)
    { cdCardTraits = singleton Terror
    , cdKeywords = singleton Keyword.Peril
    }

dreamersCurse :: CardDef
dreamersCurse =
  (treachery "06093" "Dreamer's Curse" DreamersCurse 2)
    { cdCardTraits = singleton Curse
    }

somniphobia :: CardDef
somniphobia =
  (treachery "06094" "Somniphobia" DreamersCurse 2)
    { cdCardTraits = singleton Terror
    }

deeperSlumber :: CardDef
deeperSlumber =
  (treachery "06095" "Deeper Slumber" DreamersCurse 2)
    { cdCardTraits = singleton Curse
    }

dreamlandsEclipse :: CardDef
dreamlandsEclipse =
  (treachery "06096" "Dreamlands Eclipse" Dreamlands 2)
    { cdCardTraits = singleton Power
    }

prismaticPhenomenon :: CardDef
prismaticPhenomenon =
  (treachery "06097" "Prismatic Phenomenon" Dreamlands 2)
    { cdCardTraits = singleton Power
    }

nightTerrors :: CardDef
nightTerrors =
  (treachery "06098" "Night Terrors" MergingRealities 2)
    { cdCardTraits = singleton Terror
    }

glimpseOfTheUnderworld :: CardDef
glimpseOfTheUnderworld =
  (treachery "06099" "Glimpse of the Underworld" MergingRealities 2)
    { cdCardTraits = singleton Terror
    }

threadsOfReality :: CardDef
threadsOfReality =
  (treachery "06100" "Threads of Reality" MergingRealities 2)
    { cdCardTraits = singleton Power
    }

sickeningWebs :: CardDef
sickeningWebs =
  (treachery "06103" "Sickening Webs" Spiders 2)
    { cdCardTraits = singleton Obstacle
    }

huntedByCorsairs :: CardDef
huntedByCorsairs =
  (treachery "06104" "Hunted by Corsairs" Corsairs 2)
    { cdCardTraits = singleton Scheme
    }

zoogBurrow :: CardDef
zoogBurrow =
  (treachery "06109" "Zoog Burrow" Dreamlands 1)
    { cdCardTraits = singleton Hazard
    }

songOfTheMagahBird :: CardDef
songOfTheMagahBird =
  (treachery "06153" "Song of the Magah Bird" TheSearchForKadath 2)
    { cdCardTraits = singleton Curse
    }

wondrousLands :: CardDef
wondrousLands =
  (treachery "06154" "Wondrous Lands" TheSearchForKadath 2)
    { cdCardTraits = singleton Power
    }

theHarbinger :: CardDef
theHarbinger =
  (weakness "08006" "The Harbinger")
    { cdCardTraits = setFromList [Omen, Endtimes]
    }

theZealotsSeal :: CardDef
theZealotsSeal =
  (treachery "50024" "The Zealot's Seal" ReturnToTheGathering 2)
    { cdCardTraits = setFromList [Hex]
    }

maskedHorrors :: CardDef
maskedHorrors =
  (treachery "50031" "Masked Horrors" ReturnToTheMidnightMasks 2)
    { cdCardTraits = setFromList [Power, Scheme]
    }

vaultOfEarthlyDemise :: CardDef
vaultOfEarthlyDemise =
  (treachery "50032b" "Vault of Earthly Demise" ReturnToTheDevourerBelow 1)
    { cdCardTraits = setFromList [Eldritch, Otherworld]
    }

umordhothsHunger :: CardDef
umordhothsHunger =
  (treachery "50037" "Umôrdhoth's Hunger" ReturnToTheDevourerBelow 2)
    { cdCardTraits = setFromList [Power]
    }

chillFromBelow :: CardDef
chillFromBelow =
  (treachery "50040" "Chill from Below" GhoulsOfUmordhoth 3)
    { cdCardTraits = setFromList [Hazard]
    }

maskOfUmordhoth :: CardDef
maskOfUmordhoth =
  (treachery "50043" "Mask of Umôrdhoth" TheDevourersCult 2)
    { cdCardTraits = setFromList [Item, Mask]
    }

throughTheGates :: CardDef
throughTheGates =
  (basicWeakness "51011" "Through the Gates") {cdCardTraits = setFromList [Pact, Mystery]}

unspeakableOathBloodthirst :: CardDef
unspeakableOathBloodthirst =
  (basicWeakness "52011" ("Unspeakable Oath" <:> "Bloodthirst"))
    { cdCardTraits = setFromList [Madness, Pact]
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdDeckRestrictions = [CampaignModeOnly]
    }

unspeakableOathCuriosity :: CardDef
unspeakableOathCuriosity =
  (basicWeakness "52012" ("Unspeakable Oath" <:> "Curiosity"))
    { cdCardTraits = setFromList [Madness, Pact]
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdDeckRestrictions = [CampaignModeOnly]
    }

unspeakableOathCowardice :: CardDef
unspeakableOathCowardice =
  (basicWeakness "52013" ("Unspeakable Oath" <:> "Cowardice"))
    { cdCardTraits = setFromList [Madness, Pact]
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    , cdDeckRestrictions = [CampaignModeOnly]
    }

offerYouCannotRefuse :: CardDef
offerYouCannotRefuse =
  (basicWeakness "53013" "Offer You Cannot Refuse")
    { cdCardTraits = singleton Pact
    , cdDeckRestrictions = [CampaignModeOnly]
    , cdGrantedXp = Just 2
    }

finePrint :: CardDef
finePrint = (weakness "53014" "Fine Print") {cdCardTraits = singleton Pact}

sellYourSoul :: CardDef
sellYourSoul = (weakness "53015" "Sell Your Soul") {cdCardTraits = singleton Pact}

damned :: CardDef
damned =
  (basicWeakness "54014" "Damned")
    { cdCardTraits = setFromList [Curse, Omen]
    , cdPermanent = True
    }

selfDestructive :: CardDef
selfDestructive =
  (basicWeakness "60104" "Self-Destructive") {cdCardTraits = singleton Flaw}

thriceDamnedCuriosity :: CardDef
thriceDamnedCuriosity =
  (weakness "60203" "Thrice-Damned Curiosity")
    { cdCardTraits = singleton Flaw
    }

obsessive :: CardDef
obsessive =
  (basicWeakness "60204" "Obsessive")
    { cdCardTraits = singleton Flaw
    }

darkFuture :: CardDef
darkFuture =
  (weakness "60403" "Dark Future")
    { cdCardTraits = setFromList [Omen, Endtimes]
    }

nihilism :: CardDef
nihilism =
  (basicWeakness "60404" "Nihilism")
    { cdCardTraits = singleton Madness
    }

calledByTheMists :: CardDef
calledByTheMists =
  (weakness "60503" "Called by the Mists")
    { cdCardTraits = setFromList [Curse]
    }

atychiphobia :: CardDef
atychiphobia =
  (basicWeakness "60504" "Atychiphobia")
    { cdCardTraits = setFromList [Madness]
    }

cursedSwamp :: CardDef
cursedSwamp =
  (treachery "81024" "Cursed Swamp" TheBayou 3)
    { cdCardTraits = setFromList [Hazard]
    }

spectralMist :: CardDef
spectralMist =
  (treachery "81025" "Spectral Mist" TheBayou 3)
    { cdCardTraits = setFromList [Hazard]
    }

draggedUnder :: CardDef
draggedUnder =
  (treachery "81026" "Dragged Under" TheBayou 4)
    { cdCardTraits = setFromList [Hazard]
    }

ripplesOnTheSurface :: CardDef
ripplesOnTheSurface =
  (treachery "81027" "Ripples on the Surface" TheBayou 3)
    { cdCardTraits = setFromList [Terror]
    }

curseOfTheRougarou :: CardDef
curseOfTheRougarou =
  (weakness "81029" "Curse of the Rougarou")
    { cdCardTraits = setFromList [Curse]
    , cdEncounterSet = Just CurseOfTheRougarou
    , cdEncounterSetQuantity = Just 1
    }

onTheProwl :: CardDef
onTheProwl =
  (treachery "81034" "On the Prowl" CurseOfTheRougarou 5)
    { cdKeywords = setFromList [Keyword.Surge]
    }

beastOfTheBayou :: CardDef
beastOfTheBayou = treachery "81035" "Beast of the Bayou" CurseOfTheRougarou 2

insatiableBloodlust :: CardDef
insatiableBloodlust =
  treachery "81036" "Insatiable Bloodlust" CurseOfTheRougarou 3

massHysteria :: CardDef
massHysteria =
  (treachery "82031" "Mass Hysteria" CarnevaleOfHorrors 3)
    { cdCardTraits = singleton Hazard
    , cdKeywords = singleton Keyword.Peril
    }

lostInVenice :: CardDef
lostInVenice =
  (treachery "82032" "Lost in Venice" CarnevaleOfHorrors 3)
    { cdCardTraits = singleton Blunder
    , cdKeywords = singleton Keyword.Peril
    }

watchersGaze :: CardDef
watchersGaze =
  (treachery "82033" "Watchers' Gaze" CarnevaleOfHorrors 3)
    { cdCardTraits = singleton Terror
    }

chaosInTheWater :: CardDef
chaosInTheWater =
  (treachery "82034" "Chaos in the Water" CarnevaleOfHorrors 3)
    { cdCardTraits = singleton Hazard
    }

mesmerize :: CardDef
mesmerize =
  (treachery "82035" "Mesmerize" CarnevaleOfHorrors 2)
    { cdCardTraits = singleton Hex
    }

abduction :: CardDef
abduction =
  (treachery "82036" "Abduction" CarnevaleOfHorrors 2)
    { cdCardTraits = singleton Scheme
    }

acridMiasma :: CardDef
acridMiasma =
  (treachery "82037" "Acrid Miasma" CarnevaleOfHorrors 2)
    { cdCardTraits = singleton Hazard
    }

whatHaveYouDone :: CardDef
whatHaveYouDone =
  (weakness "84007" "What Have You Done?")
    { cdCardTraits = singleton Madness
    , cdEncounterSet = Just MurderAtTheExcelsiorHotel
    , cdEncounterSetQuantity = Just 1
    }

noxiousFumes :: CardDef
noxiousFumes =
  (treachery "84023" "Noxious Fumes" MurderAtTheExcelsiorHotel 2)
    { cdCardTraits = singleton Hazard
    }

drivenToMadness :: CardDef
drivenToMadness =
  (treachery "84024" "Driven to Madness" MurderAtTheExcelsiorHotel 3)
    { cdCardTraits = singleton Curse
    }

bloodOnYourHands :: CardDef
bloodOnYourHands =
  (treachery "84025" "Blood on Your Hands" MurderAtTheExcelsiorHotel 4)
    { cdCardTraits = singleton Terror
    }

incriminatingEvidence :: CardDef
incriminatingEvidence =
  (treachery "84026" "Incriminating Evidence" MurderAtTheExcelsiorHotel 2)
    { cdCardTraits = singleton Evidence
    }

violentOutburst :: CardDef
violentOutburst =
  (treachery "84027" "Violent Outburst" MurderAtTheExcelsiorHotel 3)
    { cdCardTraits = singleton Curse
    }

encephalonSignal :: CardDef
encephalonSignal =
  (treachery "84030" "Encephalon Signal" AlienInterference 3)
    { cdCardTraits = singleton Hazard
    , cdKeywords = setFromList [Keyword.Peril]
    }

harvestedBrain :: CardDef
harvestedBrain =
  (treachery "84038" "Harvested Brain" VileExperiments 1)
    { cdCardTraits = setFromList [Ancient, Science]
    , cdRevelation = NoRevelation
    }

morbidAwareness :: CardDef
morbidAwareness =
  (treachery "84039" "Morbid Awareness" VileExperiments 3)
    { cdCardTraits = singleton Hazard
    }

chillingPresence :: CardDef
chillingPresence =
  (treachery "84042" "Chilling Presence" SinsOfThePast 3)
    { cdCardTraits = singleton Terror
    }

yaztaroth :: CardDef
yaztaroth =
  (weakness "98018" "Yaztaroth")
    { cdCardTraits = setFromList [Curse, Pact]
    , cdUnique = True
    }

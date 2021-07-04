module Arkham.Treachery.Cards where

import Arkham.Prelude

import Arkham.Types.Card.CardCode
import Arkham.Types.Card.CardDef
import Arkham.Types.Card.CardType
import Arkham.Types.ClassSymbol
import Arkham.Types.EncounterSet hiding (Dunwich)
import qualified Arkham.Types.EncounterSet as EncounterSet
import qualified Arkham.Types.Keyword as Keyword
import Arkham.Types.Name
import Arkham.Types.Trait

baseTreachery :: CardCode -> Name -> Maybe EncounterSet -> Bool -> CardDef
baseTreachery cardCode name mEncounterSet isWeakness = CardDef
  { cdCardCode = cardCode
  , cdName = name
  , cdCost = Nothing
  , cdLevel = 0
  , cdCardType = if isWeakness then PlayerTreacheryType else TreacheryType
  , cdWeakness = isWeakness
  , cdClassSymbol = if isWeakness then Just Neutral else Nothing
  , cdSkills = mempty
  , cdCardTraits = mempty
  , cdKeywords = mempty
  , cdFast = False
  , cdWindows = mempty
  , cdAction = Nothing
  , cdRevelation = True
  , cdVictoryPoints = Nothing
  , cdCommitRestrictions = mempty
  , cdAttackOfOpportunityModifiers = mempty
  , cdPermanent = False
  , cdEncounterSet = mEncounterSet
  , cdUnique = False
  }

weakness :: CardCode -> Name -> CardDef
weakness cardCode name = baseTreachery cardCode name Nothing True

treachery :: CardCode -> Name -> EncounterSet -> CardDef
treachery cardCode name encounterSet =
  baseTreachery cardCode name (Just encounterSet) False

allPlayerTreacheryCards :: HashMap CardCode CardDef
allPlayerTreacheryCards = mapFromList $ map
  (toCardCode &&& id)
  [ abandonedAndAlone
  , acrossSpaceAndTime
  , amnesia
  , atychiphobia
  , chronophobia
  , coverUp
  , curseOfTheRougarou
  , finalRhapsody
  , haunted
  , hospitalDebts
  , hypochondria
  , indebted
  , internalInjury
  , paranoia
  , psychosis
  , rexsCurse
  , searchingForIzzie
  , smiteTheWicked
  , wrackedByNightmares
  ]

allEncounterTreacheryCards :: HashMap CardCode CardDef
allEncounterTreacheryCards = mapFromList $ map
  (toCardCode &&& id)
  [ placeholderTreachery
  , alteredBeast
  , ancientEvils
  , arcaneBarrier
  , arousingSuspicions
  , attractingAttention
  , beastOfTheBayou
  , beyondTheVeil
  , brokenRails
  , chillFromBelow
  , clawsOfSteam
  , collapsingReality
  , cryptChill
  , cursedLuck
  , cursedSwamp
  , dissonantVoices
  , draggedUnder
  , dreamsOfRlyeh
  , eagerForDeath
  , ephemeralExhibits
  , falseLead
  , frozenInFear
  , graspingHands
  , huntedDown
  , huntingShadow
  , insatiableBloodlust
  , kidnapped
  , lightOfAforgomon
  , lockedDoor
  , maskOfUmordhoth
  , maskedHorrors
  , mysteriousChanting
  , obscuringFog
  , offerOfPower
  , onTheProwl
  , onWingsOfDarkness
  , passageIntoTheVeil
  , psychopompsSong
  , pushedIntoTheBeyond
  , ripplesOnTheSurface
  , ritesHowled
  , rottingRemains
  , rottingRemainsBloodOnTheAltar
  , ruinAndDestruction
  , shadowSpawned
  , slitheringBehindYou
  , somethingInTheDrinks
  , sordidAndSilent
  , spacesBetween
  , spectralMist
  , stalkedInTheDark
  , strangeSigns
  , terrorFromBeyond
  , theCreaturesTracks
  , theYellowSign
  , theZealotsSeal
  , toweringBeasts
  , twistOfFate
  , umordhothsHunger
  , umordhothsWrath
  , unhallowedCountry
  , vastExpanse
  , vaultOfEarthlyDemise
  , visionsOfFuturesPast
  , vortexOfTime
  , wormhole
  ]

placeholderTreachery :: CardDef
placeholderTreachery = treachery "treachery" "Placeholder Treachery Card" Test

coverUp :: CardDef
coverUp = (weakness "01007" "Cover Up") { cdCardTraits = setFromList [Task] }

hospitalDebts :: CardDef
hospitalDebts =
  (weakness "01011" "Hospital Debts") { cdCardTraits = setFromList [Task] }

abandonedAndAlone :: CardDef
abandonedAndAlone = (weakness "01015" "Abandoned and Alone")
  { cdCardTraits = setFromList [Madness]
  }

amnesia :: CardDef
amnesia = (weakness "01096" "Amnesia") { cdCardTraits = setFromList [Madness] }

paranoia :: CardDef
paranoia =
  (weakness "01097" "Paranoia") { cdCardTraits = setFromList [Madness] }

haunted :: CardDef
haunted = (weakness "01098" "Haunted") { cdCardTraits = setFromList [Curse] }

psychosis :: CardDef
psychosis =
  (weakness "01099" "Psychosis") { cdCardTraits = setFromList [Madness] }

hypochondria :: CardDef
hypochondria =
  (weakness "01100" "Hypochondria") { cdCardTraits = setFromList [Madness] }


huntingShadow :: CardDef
huntingShadow = (treachery "01135" "Hunting Shadow" TheMidnightMasks)
  { cdCardTraits = setFromList [Curse]
  , cdKeywords = setFromList [Keyword.Peril]
  }

falseLead :: CardDef
falseLead = treachery "01136" "False Lead" TheMidnightMasks

umordhothsWrath :: CardDef
umordhothsWrath = (treachery "01158" "Umôrdhoth's Wrath" TheDevourerBelow)
  { cdCardTraits = setFromList [Curse]
  }

graspingHands :: CardDef
graspingHands = (treachery "01162" "Grasping Hands" Ghouls)
  { cdCardTraits = setFromList [Hazard]
  }

rottingRemains :: CardDef
rottingRemains = (treachery "01163" "Rotting Remains" StrikingFear)
  { cdCardTraits = setFromList [Terror]
  }

frozenInFear :: CardDef
frozenInFear = (treachery "01164" "Frozen in Fear" StrikingFear)
  { cdCardTraits = setFromList [Terror]
  }

dissonantVoices :: CardDef
dissonantVoices = (treachery "01165" "Dissonant Voices" StrikingFear)
  { cdCardTraits = setFromList [Terror]
  }

ancientEvils :: CardDef
ancientEvils = (treachery "01166" "Ancient Evils" AncientEvils)
  { cdCardTraits = setFromList [Omen]
  }

cryptChill :: CardDef
cryptChill = (treachery "01167" "Crypt Chill" ChillingCold)
  { cdCardTraits = setFromList [Hazard]
  }

obscuringFog :: CardDef
obscuringFog = (treachery "01168" "Obscuring Fog" ChillingCold)
  { cdCardTraits = setFromList [Hazard]
  }

mysteriousChanting :: CardDef
mysteriousChanting = (treachery "01171" "Mysterious Chanting" DarkCult)
  { cdCardTraits = setFromList [Hex]
  }

onWingsOfDarkness :: CardDef
onWingsOfDarkness = treachery "01173" "On Wings of Darkness" Nightgaunts

lockedDoor :: CardDef
lockedDoor = (treachery "01174" "Locked Door" LockedDoors)
  { cdCardTraits = setFromList [Obstacle]
  }

theYellowSign :: CardDef
theYellowSign = (treachery "01176" "The Yellow Sign" AgentsOfHastur)
  { cdCardTraits = setFromList [Omen]
  }

offerOfPower :: CardDef
offerOfPower = (treachery "01178" "Offer of Power" AgentsOfYogSothoth)
  { cdCardTraits = setFromList [Pact]
  , cdKeywords = setFromList [Keyword.Peril]
  }

dreamsOfRlyeh :: CardDef
dreamsOfRlyeh = (treachery "01182" "Dreams of R'lyeh" AgentsOfCthulhu)
  { cdCardTraits = setFromList [Omen]
  }

smiteTheWicked :: CardDef
smiteTheWicked =
  (weakness "02007" "Smite the Wicked") { cdCardTraits = setFromList [Task] }

rexsCurse :: CardDef
rexsCurse =
  (weakness "02009" "Rex's Curse") { cdCardTraits = setFromList [Curse] }

searchingForIzzie :: CardDef
searchingForIzzie =
  (weakness "02011" "Searching for Izzie") { cdCardTraits = setFromList [Task] }

finalRhapsody :: CardDef
finalRhapsody =
  (weakness "02013" "Final Rhapsody") { cdCardTraits = setFromList [Endtimes] }

wrackedByNightmares :: CardDef
wrackedByNightmares = (weakness "02015" "Wracked by Nightmares")
  { cdCardTraits = setFromList [Madness]
  }

indebted :: CardDef
indebted = (weakness "02037" "Indebted")
  { cdCardTraits = singleton Flaw
  , cdPermanent = True
  }

internalInjury :: CardDef
internalInjury =
  (weakness "02038" "Internal Injury") { cdCardTraits = singleton Injury }

chronophobia :: CardDef
chronophobia =
  (weakness "02039" "Chronophobia") { cdCardTraits = singleton Madness }

somethingInTheDrinks :: CardDef
somethingInTheDrinks =
  (treachery "02081" "Something in the Drinks" TheHouseAlwaysWins)
    { cdCardTraits = setFromList [Poison, Illicit]
    , cdKeywords = setFromList [Keyword.Surge]
    }

arousingSuspicions :: CardDef
arousingSuspicions = treachery "02082" "Arousing Suspicions" TheHouseAlwaysWins

visionsOfFuturesPast :: CardDef
visionsOfFuturesPast = (treachery "02083" "Visions of Futures Past" Sorcery)
  { cdCardTraits = setFromList [Hex]
  }

beyondTheVeil :: CardDef
beyondTheVeil = (treachery "02084" "Beyond the Veil" Sorcery)
  { cdCardTraits = setFromList [Hex]
  , cdKeywords = setFromList [Keyword.Surge]
  }

lightOfAforgomon :: CardDef
lightOfAforgomon = (treachery "02085" "Light of Aforgomon" BishopsThralls)
  { cdCardTraits = setFromList [Pact, Power]
  , cdKeywords = setFromList [Keyword.Peril]
  }

unhallowedCountry :: CardDef
unhallowedCountry =
  (treachery "02088" "Unhallowed Country" EncounterSet.Dunwich)
    { cdCardTraits = setFromList [Terror]
    }

sordidAndSilent :: CardDef
sordidAndSilent = (treachery "02089" "Sordid and Silent" EncounterSet.Dunwich)
  { cdCardTraits = setFromList [Terror]
  }

eagerForDeath :: CardDef
eagerForDeath = (treachery "02091" "Eager for Death" Whippoorwills)
  { cdCardTraits = setFromList [Omen]
  }

cursedLuck :: CardDef
cursedLuck = (treachery "02092" "Cursed Luck" BadLuck)
  { cdCardTraits = setFromList [Omen]
  }

twistOfFate :: CardDef
twistOfFate = (treachery "02093" "Twist of Fate" BadLuck)
  { cdCardTraits = setFromList [Omen]
  }

alteredBeast :: CardDef
alteredBeast = (treachery "02096" "Altered Beast" BeastThralls)
  { cdCardTraits = setFromList [Power]
  }

huntedDown :: CardDef
huntedDown = (treachery "02099" "Hunted Down" NaomisCrew)
  { cdCardTraits = setFromList [Tactic]
  }

pushedIntoTheBeyond :: CardDef
pushedIntoTheBeyond = (treachery "02100" "Pushed into the Beyond" TheBeyond)
  { cdCardTraits = setFromList [Hex]
  }

terrorFromBeyond :: CardDef
terrorFromBeyond = (treachery "02101" "Terror from Beyond" TheBeyond)
  { cdCardTraits = setFromList [Hex, Terror]
  , cdKeywords = setFromList [Keyword.Peril]
  }

arcaneBarrier :: CardDef
arcaneBarrier = (treachery "02102" "Arcane Barrier" TheBeyond)
  { cdCardTraits = setFromList [Hex, Obstacle]
  }

shadowSpawned :: CardDef
shadowSpawned = (treachery "02142" "Shadow-spawned" TheMiskatonicMuseum)
  { cdCardTraits = singleton Power
  }

stalkedInTheDark :: CardDef
stalkedInTheDark = (treachery "02143" "Stalked in the Dark" TheMiskatonicMuseum
                   )
  { cdCardTraits = singleton Tactic
  }

passageIntoTheVeil :: CardDef
passageIntoTheVeil =
  (treachery "02144" "Passage into the Veil" TheMiskatonicMuseum)
    { cdCardTraits = singleton Power
    }

ephemeralExhibits :: CardDef
ephemeralExhibits = (treachery "02145" "Ephemeral Exhibits" TheMiskatonicMuseum
                    )
  { cdCardTraits = singleton Terror
  }

slitheringBehindYou :: CardDef
slitheringBehindYou =
  treachery "02146" "Slithering Behind You" TheMiskatonicMuseum

acrossSpaceAndTime :: CardDef
acrossSpaceAndTime = (weakness "02178" "Across Space and Time")
  { cdCardTraits = setFromList [Madness]
  , cdEncounterSet = Just TheEssexCountyExpress
  }

clawsOfSteam :: CardDef
clawsOfSteam = (treachery "02180" "Claws of Steam" TheEssexCountyExpress)
  { cdCardTraits = singleton Power
  }

brokenRails :: CardDef
brokenRails = (treachery "02181" "Broken Rails" TheEssexCountyExpress)
  { cdCardTraits = singleton Hazard
  }

kidnapped :: CardDef
kidnapped = treachery "02220" "Kidnapped!" BloodOnTheAltar

psychopompsSong :: CardDef
psychopompsSong = (treachery "02221" "Psychopomp's Song" BloodOnTheAltar)
  { cdCardTraits = singleton Omen
  , cdKeywords = setFromList [Keyword.Surge, Keyword.Peril]
  }

strangeSigns :: CardDef
strangeSigns = (treachery "02222" "Strange Signs" BloodOnTheAltar)
  { cdCardTraits = singleton Omen
  }

rottingRemainsBloodOnTheAltar :: CardDef
rottingRemainsBloodOnTheAltar =
  (treachery "02223" "Rotting Remains" BloodOnTheAltar)
    { cdCardTraits = singleton Terror
    }

toweringBeasts :: CardDef
toweringBeasts = (treachery "02256" "Towering Beasts" UndimensionedAndUnseen)
  { cdKeywords = singleton Keyword.Peril
  }

ruinAndDestruction :: CardDef
ruinAndDestruction =
  (treachery "02257" "Ruin and Destruction" UndimensionedAndUnseen)
    { cdCardTraits = singleton Hazard
    }

attractingAttention :: CardDef
attractingAttention =
  (treachery "02258" "Attracting Attention" UndimensionedAndUnseen)
    { cdKeywords = singleton Keyword.Surge
    }

theCreaturesTracks :: CardDef
theCreaturesTracks =
  (treachery "02259" "The Creatures' Tracks" UndimensionedAndUnseen)
    { cdCardTraits = singleton Terror
    , cdKeywords = singleton Keyword.Peril
    }

ritesHowled :: CardDef
ritesHowled = (treachery "02296" "Rites Howled" WhereDoomAwaits)
  { cdCardTraits = singleton Hex
  }

spacesBetween :: CardDef
spacesBetween = (treachery "02297" "Spaces Between" WhereDoomAwaits)
  { cdCardTraits = setFromList [Hex, Hazard]
  }

vortexOfTime :: CardDef
vortexOfTime = (treachery "02298" "Vortex of Time" WhereDoomAwaits)
  { cdCardTraits = setFromList [Hex, Hazard]
  }

collapsingReality :: CardDef
collapsingReality = (treachery "02331" "Collapsing Reality" LostInTimeAndSpace)
  { cdCardTraits = setFromList [Hazard]
  }

wormhole :: CardDef
wormhole = (treachery "02332" "Wormhole" LostInTimeAndSpace)
  { cdCardTraits = setFromList [Hazard]
  }

vastExpanse :: CardDef
vastExpanse = (treachery "02333" "Vast Expanse" LostInTimeAndSpace)
  { cdCardTraits = setFromList [Terror]
  }

theZealotsSeal :: CardDef
theZealotsSeal = (treachery "50024" "The Zealot's Seal" ReturnToTheGathering)
  { cdCardTraits = setFromList [Hex]
  }

maskedHorrors :: CardDef
maskedHorrors = (treachery "50031" "Masked Horrors" ReturnToTheMidnightMasks)
  { cdCardTraits = setFromList [Power, Scheme]
  }

vaultOfEarthlyDemise :: CardDef
vaultOfEarthlyDemise =
  (treachery "50032b" "Vault of Earthly Demise" ReturnToTheDevourerBelow)
    { cdCardTraits = setFromList [Eldritch, Otherworld]
    }

umordhothsHunger :: CardDef
umordhothsHunger =
  (treachery "50037" "Umôrdhoth's Hunger" ReturnToTheDevourerBelow)
    { cdCardTraits = setFromList [Power]
    }

chillFromBelow :: CardDef
chillFromBelow = (treachery "50040" "Chill from Below" GhoulsOfUmordhoth)
  { cdCardTraits = setFromList [Hazard]
  }

maskOfUmordhoth :: CardDef
maskOfUmordhoth = (treachery "50043" "Mask of Umôrdhoth" TheDevourersCult)
  { cdCardTraits = setFromList [Item, Mask]
  }

atychiphobia :: CardDef
atychiphobia =
  (weakness "60504" "Atychiphobia") { cdCardTraits = setFromList [Madness] }

cursedSwamp :: CardDef
cursedSwamp = (treachery "81024" "Cursed Swamp" TheBayou)
  { cdCardTraits = setFromList [Hazard]
  }

spectralMist :: CardDef
spectralMist = (treachery "81025" "Spectral Mist" TheBayou)
  { cdCardTraits = setFromList [Hazard]
  }

draggedUnder :: CardDef
draggedUnder = (treachery "81026" "Dragged Under" TheBayou)
  { cdCardTraits = setFromList [Hazard]
  }

ripplesOnTheSurface :: CardDef
ripplesOnTheSurface = (treachery "81027" "Ripples on the Surface" TheBayou)
  { cdCardTraits = setFromList [Terror]
  }

onTheProwl :: CardDef
onTheProwl = (treachery "81034" "On the Prowl" CurseOfTheRougarou)
  { cdKeywords = setFromList [Keyword.Surge]
  }

beastOfTheBayou :: CardDef
beastOfTheBayou = treachery "81035" "Beast of the Bayou" CurseOfTheRougarou

insatiableBloodlust :: CardDef
insatiableBloodlust =
  treachery "81036" "Insatiable Bloodlust" CurseOfTheRougarou

curseOfTheRougarou :: CardDef
curseOfTheRougarou = (weakness "81029" "Curse of the Rougarou")
  { cdCardTraits = setFromList [Curse]
  , cdEncounterSet = Just CurseOfTheRougarou
  }


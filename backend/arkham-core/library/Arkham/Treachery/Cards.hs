module Arkham.Treachery.Cards where

import Arkham.Prelude

import Arkham.Types.Asset.Uses
import Arkham.Types.Card.CardCode
import Arkham.Types.Card.CardDef
import Arkham.Types.Card.CardType
import Arkham.Types.ClassSymbol
import Arkham.Types.EncounterSet hiding (Byakhee, Dunwich)
import Arkham.Types.EncounterSet qualified as EncounterSet
import Arkham.Types.Keyword qualified as Keyword
import Arkham.Types.Name
import Arkham.Types.Trait

baseTreachery
  :: CardCode
  -> Name
  -> Maybe (EncounterSet, Int)
  -> Maybe CardSubType
  -> CardDef
baseTreachery cardCode name mEncounterSet isWeakness = CardDef
  { cdCardCode = cardCode
  , cdName = name
  , cdRevealedName = Nothing
  , cdCost = Nothing
  , cdLevel = 0
  , cdCardType = if isJust isWeakness
    then PlayerTreacheryType
    else TreacheryType
  , cdCardSubType = isWeakness
  , cdClassSymbol = if isJust isWeakness then Just Neutral else Nothing
  , cdSkills = mempty
  , cdCardTraits = mempty
  , cdRevealedCardTraits = mempty
  , cdKeywords = mempty
  , cdFastWindow = Nothing
  , cdAction = Nothing
  , cdRevelation = True
  , cdVictoryPoints = Nothing
  , cdCriteria = mempty
  , cdCommitRestrictions = mempty
  , cdAttackOfOpportunityModifiers = mempty
  , cdPermanent = False
  , cdEncounterSet = fst <$> mEncounterSet
  , cdEncounterSetQuantity = snd <$> mEncounterSet
  , cdUnique = False
  , cdDoubleSided = False
  , cdLimits = []
  , cdExceptional = False
  , cdUses = NoUses
  , cdPlayableFromDiscard = False
  , cdStage = Nothing
  , cdSlots = []
  }

weakness :: CardCode -> Name -> CardDef
weakness cardCode name = baseTreachery cardCode name Nothing (Just Weakness)

basicWeakness :: CardCode -> Name -> CardDef
basicWeakness cardCode name =
  baseTreachery cardCode name Nothing (Just BasicWeakness)

treachery :: CardCode -> Name -> EncounterSet -> Int -> CardDef
treachery cardCode name encounterSet encounterSetQuantity = baseTreachery
  cardCode
  name
  (Just (encounterSet, encounterSetQuantity))
  Nothing

allTreacheryCards :: HashMap CardCode CardDef
allTreacheryCards = allPlayerTreacheryCards <> allEncounterTreacheryCards

allPlayerTreacheryCards :: HashMap CardCode CardDef
allPlayerTreacheryCards = mapFromList $ map
  (toCardCode &&& id)
  [ abandonedAndAlone
  , acrossSpaceAndTime
  , amnesia
  , angeredSpirits
  , atychiphobia
  , calledByTheMists
  , chronophobia
  , coverUp
  , crisisOfIdentity
  , curseOfTheRougarou
  , drawingTheSign
  , finalRhapsody
  , haunted
  , hospitalDebts
  , hypochondria
  , indebted
  , internalInjury
  , overzealous
  , paranoia
  , psychosis
  , rexsCurse
  , searchingForIzzie
  , shellShock
  , smiteTheWicked
  , starsOfHyades
  , wrackedByNightmares
  ]

allEncounterTreacheryCards :: HashMap CardCode CardDef
allEncounterTreacheryCards = mapFromList $ map
  (toCardCode &&& id)
  [ abduction
  , acridMiasma
  , alteredBeast
  , ancientEvils
  , arcaneBarrier
  , arousingSuspicions
  , attractingAttention
  , beastOfTheBayou
  , beyondTheVeil
  , blackStarsRise
  , brokenRails
  , chaosInTheWater
  , chillFromBelow
  , clawsOfSteam
  , collapsingReality
  , corrosion
  , cryptChill
  , cursedLuck
  , cursedSwamp
  , danceOfTheYellowKing
  , descentIntoMadness
  , dissonantVoices
  , draggedUnder
  , dreamsOfRlyeh
  , eagerForDeath
  , ephemeralExhibits
  , falseLead
  , fineDining
  , frozenInFear
  , giftOfMadnessMisery
  , giftOfMadnessPity
  , graspingHands
  , huntedByByakhee
  , huntedDown
  , huntingShadow
  , insatiableBloodlust
  , kidnapped
  , ledAstray
  , lightOfAforgomon
  , lockedDoor
  , lostInVenice
  , markedByTheSign
  , maskOfUmordhoth
  , maskedHorrors
  , massHysteria
  , mesmerize
  , mysteriousChanting
  , obscuringFog
  , offerOfPower
  , onTheProwl
  , onWingsOfDarkness
  , oozeAndFilth
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
  , spiresOfCarcosa
  , spiritsTorment
  , stalkedInTheDark
  , straitjacket
  , strangeSigns
  , terrorFromBeyond
  , theCreaturesTracks
  , theCultsSearch
  , theKingsEdict
  , thePaleMaskBeckons
  , theYellowSign
  , theZealotsSeal
  , toughCrowd
  , toweringBeasts
  , twistOfFate
  , twistedToHisWill
  , umordhothsHunger
  , umordhothsWrath
  , unhallowedCountry
  , vastExpanse
  , vaultOfEarthlyDemise
  , visionsOfFuturesPast
  , vortexOfTime
  , wallsClosingIn
  , watchersGaze
  , whispersInYourHeadDismay
  , whispersInYourHeadDread
  , whispersInYourHeadAnxiety
  , whispersInYourHeadDoubt
  , wormhole
  ]

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
amnesia =
  (basicWeakness "01096" "Amnesia") { cdCardTraits = setFromList [Madness] }

paranoia :: CardDef
paranoia =
  (basicWeakness "01097" "Paranoia") { cdCardTraits = setFromList [Madness] }

haunted :: CardDef
haunted =
  (basicWeakness "01098" "Haunted") { cdCardTraits = setFromList [Curse] }

psychosis :: CardDef
psychosis =
  (basicWeakness "01099" "Psychosis") { cdCardTraits = setFromList [Madness] }

hypochondria :: CardDef
hypochondria = (basicWeakness "01100" "Hypochondria")
  { cdCardTraits = setFromList [Madness]
  }

huntingShadow :: CardDef
huntingShadow = (treachery "01135" "Hunting Shadow" TheMidnightMasks 3)
  { cdCardTraits = setFromList [Curse]
  , cdKeywords = setFromList [Keyword.Peril]
  }

falseLead :: CardDef
falseLead = treachery "01136" "False Lead" TheMidnightMasks 2

umordhothsWrath :: CardDef
umordhothsWrath = (treachery "01158" "Umôrdhoth's Wrath" TheDevourerBelow 2)
  { cdCardTraits = setFromList [Curse]
  }

graspingHands :: CardDef
graspingHands = (treachery "01162" "Grasping Hands" Ghouls 3)
  { cdCardTraits = setFromList [Hazard]
  }

rottingRemains :: CardDef
rottingRemains = (treachery "01163" "Rotting Remains" StrikingFear 3)
  { cdCardTraits = setFromList [Terror]
  }

frozenInFear :: CardDef
frozenInFear = (treachery "01164" "Frozen in Fear" StrikingFear 2)
  { cdCardTraits = setFromList [Terror]
  }

dissonantVoices :: CardDef
dissonantVoices = (treachery "01165" "Dissonant Voices" StrikingFear 2)
  { cdCardTraits = setFromList [Terror]
  }

ancientEvils :: CardDef
ancientEvils = (treachery "01166" "Ancient Evils" AncientEvils 3)
  { cdCardTraits = setFromList [Omen]
  }

cryptChill :: CardDef
cryptChill = (treachery "01167" "Crypt Chill" ChillingCold 2)
  { cdCardTraits = setFromList [Hazard]
  }

obscuringFog :: CardDef
obscuringFog = (treachery "01168" "Obscuring Fog" ChillingCold 2)
  { cdCardTraits = setFromList [Hazard]
  }

mysteriousChanting :: CardDef
mysteriousChanting = (treachery "01171" "Mysterious Chanting" DarkCult 2)
  { cdCardTraits = setFromList [Hex]
  }

onWingsOfDarkness :: CardDef
onWingsOfDarkness = treachery "01173" "On Wings of Darkness" Nightgaunts 2

lockedDoor :: CardDef
lockedDoor = (treachery "01174" "Locked Door" LockedDoors 2)
  { cdCardTraits = setFromList [Obstacle]
  }

theYellowSign :: CardDef
theYellowSign = (treachery "01176" "The Yellow Sign" AgentsOfHastur 2)
  { cdCardTraits = setFromList [Omen]
  }

offerOfPower :: CardDef
offerOfPower = (treachery "01178" "Offer of Power" AgentsOfYogSothoth 2)
  { cdCardTraits = setFromList [Pact]
  , cdKeywords = setFromList [Keyword.Peril]
  }

dreamsOfRlyeh :: CardDef
dreamsOfRlyeh = (treachery "01182" "Dreams of R'lyeh" AgentsOfCthulhu 2)
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
indebted = (basicWeakness "02037" "Indebted")
  { cdCardTraits = singleton Flaw
  , cdPermanent = True
  }

internalInjury :: CardDef
internalInjury =
  (basicWeakness "02038" "Internal Injury") { cdCardTraits = singleton Injury }

chronophobia :: CardDef
chronophobia =
  (basicWeakness "02039" "Chronophobia") { cdCardTraits = singleton Madness }

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
visionsOfFuturesPast = (treachery "02083" "Visions of Futures Past" Sorcery 3)
  { cdCardTraits = setFromList [Hex]
  }

beyondTheVeil :: CardDef
beyondTheVeil = (treachery "02084" "Beyond the Veil" Sorcery 3)
  { cdCardTraits = setFromList [Hex]
  , cdKeywords = setFromList [Keyword.Surge]
  }

lightOfAforgomon :: CardDef
lightOfAforgomon = (treachery "02085" "Light of Aforgomon" BishopsThralls 2)
  { cdCardTraits = setFromList [Pact, Power]
  , cdKeywords = setFromList [Keyword.Peril]
  }

unhallowedCountry :: CardDef
unhallowedCountry =
  (treachery "02088" "Unhallowed Country" EncounterSet.Dunwich 2)
    { cdCardTraits = setFromList [Terror]
    }

sordidAndSilent :: CardDef
sordidAndSilent = (treachery "02089" "Sordid and Silent" EncounterSet.Dunwich 2
                  )
  { cdCardTraits = setFromList [Terror]
  }

eagerForDeath :: CardDef
eagerForDeath = (treachery "02091" "Eager for Death" Whippoorwills 2)
  { cdCardTraits = setFromList [Omen]
  }

cursedLuck :: CardDef
cursedLuck = (treachery "02092" "Cursed Luck" BadLuck 3)
  { cdCardTraits = setFromList [Omen]
  }

twistOfFate :: CardDef
twistOfFate = (treachery "02093" "Twist of Fate" BadLuck 3)
  { cdCardTraits = setFromList [Omen]
  }

alteredBeast :: CardDef
alteredBeast = (treachery "02096" "Altered Beast" BeastThralls 2)
  { cdCardTraits = setFromList [Power]
  }

huntedDown :: CardDef
huntedDown = (treachery "02099" "Hunted Down" NaomisCrew 2)
  { cdCardTraits = setFromList [Tactic]
  }

pushedIntoTheBeyond :: CardDef
pushedIntoTheBeyond = (treachery "02100" "Pushed into the Beyond" TheBeyond 2)
  { cdCardTraits = setFromList [Hex]
  }

terrorFromBeyond :: CardDef
terrorFromBeyond = (treachery "02101" "Terror from Beyond" TheBeyond 2)
  { cdCardTraits = setFromList [Hex, Terror]
  , cdKeywords = setFromList [Keyword.Peril]
  }

arcaneBarrier :: CardDef
arcaneBarrier = (treachery "02102" "Arcane Barrier" TheBeyond 2)
  { cdCardTraits = setFromList [Hex, Obstacle]
  }

shadowSpawned :: CardDef
shadowSpawned = (treachery "02142" "Shadow-spawned" TheMiskatonicMuseum 1)
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
acrossSpaceAndTime = (weakness "02178" "Across Space and Time")
  { cdCardTraits = setFromList [Madness]
  , cdEncounterSet = Just TheEssexCountyExpress
  , cdEncounterSetQuantity = Just 4
  }

clawsOfSteam :: CardDef
clawsOfSteam = (treachery "02180" "Claws of Steam" TheEssexCountyExpress 3)
  { cdCardTraits = singleton Power
  }

brokenRails :: CardDef
brokenRails = (treachery "02181" "Broken Rails" TheEssexCountyExpress 3)
  { cdCardTraits = singleton Hazard
  }

kidnapped :: CardDef
kidnapped = treachery "02220" "Kidnapped!" BloodOnTheAltar 3

psychopompsSong :: CardDef
psychopompsSong = (treachery "02221" "Psychopomp's Song" BloodOnTheAltar 2)
  { cdCardTraits = singleton Omen
  , cdKeywords = setFromList [Keyword.Surge, Keyword.Peril]
  }

strangeSigns :: CardDef
strangeSigns = (treachery "02222" "Strange Signs" BloodOnTheAltar 2)
  { cdCardTraits = singleton Omen
  }

rottingRemainsBloodOnTheAltar :: CardDef
rottingRemainsBloodOnTheAltar =
  (treachery "02223" "Rotting Remains" BloodOnTheAltar 3)
    { cdCardTraits = singleton Terror
    }

toweringBeasts :: CardDef
toweringBeasts = (treachery "02256" "Towering Beasts" UndimensionedAndUnseen 4)
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
ritesHowled = (treachery "02296" "Rites Howled" WhereDoomAwaits 3)
  { cdCardTraits = singleton Hex
  }

spacesBetween :: CardDef
spacesBetween = (treachery "02297" "Spaces Between" WhereDoomAwaits 3)
  { cdCardTraits = setFromList [Hex, Hazard]
  }

vortexOfTime :: CardDef
vortexOfTime = (treachery "02298" "Vortex of Time" WhereDoomAwaits 3)
  { cdCardTraits = setFromList [Hex, Hazard]
  }

collapsingReality :: CardDef
collapsingReality =
  (treachery "02331" "Collapsing Reality" LostInTimeAndSpace 3)
    { cdCardTraits = setFromList [Hazard]
    }

wormhole :: CardDef
wormhole = (treachery "02332" "Wormhole" LostInTimeAndSpace 2)
  { cdCardTraits = setFromList [Hazard]
  }

vastExpanse :: CardDef
vastExpanse = (treachery "02333" "Vast Expanse" LostInTimeAndSpace 3)
  { cdCardTraits = setFromList [Terror]
  }

shellShock :: CardDef
shellShock =
  (weakness "03008" "Shell Shock") { cdCardTraits = setFromList [Flaw] }

starsOfHyades :: CardDef
starsOfHyades =
  (weakness "03013" "Stars of Hyades") { cdCardTraits = setFromList [Curse] }

angeredSpirits :: CardDef
angeredSpirits =
  (weakness "03015" "Angered Spirits") { cdCardTraits = singleton Task }

crisisOfIdentity :: CardDef
crisisOfIdentity =
  (weakness "03019" "Crisis of Identity") { cdCardTraits = singleton Madness }

overzealous :: CardDef
overzealous =
  (basicWeakness "03040" "Overzealous") { cdCardTraits = singleton Flaw }

drawingTheSign :: CardDef
drawingTheSign = (basicWeakness "03041" "Drawing the Sign")
  { cdCardTraits = setFromList [Pact, Madness]
  }

fineDining :: CardDef
fineDining = (treachery "03082" "Fine Dining" TheLastKing 2)
  { cdCardTraits = singleton Terror
  , cdKeywords = singleton Keyword.Peril
  }

toughCrowd :: CardDef
toughCrowd = (treachery "03083" "Tough Crowd" TheLastKing 2)
  { cdCardTraits = singleton Hazard
  }

whispersInYourHeadDismay :: CardDef
whispersInYourHeadDismay =
  (treachery "03084a" "Whispers in Your Head (Dismay)" Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

whispersInYourHeadDread :: CardDef
whispersInYourHeadDread =
  (treachery "03084b" "Whispers in Your Head (Dread)" Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

whispersInYourHeadAnxiety :: CardDef
whispersInYourHeadAnxiety =
  (treachery "03084c" "Whispers in Your Head (Anxiety)" Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

whispersInYourHeadDoubt :: CardDef
whispersInYourHeadDoubt =
  (treachery "03084d" "Whispers in Your Head (Doubt)" Delusions 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

descentIntoMadness :: CardDef
descentIntoMadness = (treachery "03085" "Descent into Madness" Delusions 2)
  { cdCardTraits = singleton Terror
  , cdKeywords = singleton Keyword.Surge
  }

huntedByByakhee :: CardDef
huntedByByakhee = (treachery "03087" "Hunted by Byakhee" EncounterSet.Byakhee 2
                  )
  { cdCardTraits = singleton Pact
  }

blackStarsRise :: CardDef
blackStarsRise = (treachery "03090" "Black Stars Rise" EvilPortents 2)
  { cdCardTraits = singleton Omen
  }

spiresOfCarcosa :: CardDef
spiresOfCarcosa = (treachery "03091" "Spires of Carcosa" EvilPortents 2)
  { cdCardTraits = singleton Omen
  }

twistedToHisWill :: CardDef
twistedToHisWill = (treachery "03092" "Twisted to His Will" EvilPortents 2)
  { cdCardTraits = singleton Pact
  }

danceOfTheYellowKing :: CardDef
danceOfTheYellowKing =
  (treachery "03097" "Dance of the Yellow King" HastursGift 2)
    { cdCardTraits = singleton Pact
    }

ledAstray :: CardDef
ledAstray = (treachery "03145" "Led Astray" EchoesOfThePast 3)
  { cdCardTraits = singleton Scheme
  , cdKeywords = singleton Keyword.Peril
  }

theCultsSearch :: CardDef
theCultsSearch = (treachery "03146" "The Cult's Search" EchoesOfThePast 2)
  { cdCardTraits = singleton Scheme
  }

spiritsTorment :: CardDef
spiritsTorment = (treachery "03094" "Spirit's Torment" Hauntings 2)
  { cdCardTraits = setFromList [Curse, Geist]
  }

theKingsEdict :: CardDef
theKingsEdict = (treachery "03100" "The King's Edict" CultOfTheYellowSign 2)
  { cdCardTraits = singleton Pact
  }

oozeAndFilth :: CardDef
oozeAndFilth = (treachery "03101" "Ooze and Filth" DecayAndFilth 2)
  { cdCardTraits = singleton Hazard
  }

corrosion :: CardDef
corrosion = (treachery "03102" "Corrosion" DecayAndFilth 2)
  { cdCardTraits = singleton Hazard
  }

markedByTheSign :: CardDef
markedByTheSign = (treachery "03104" "Marked by the Sign" TheStranger 2)
  { cdCardTraits = singleton Pact
  , cdKeywords = singleton Keyword.Peril
  }

thePaleMaskBeckons :: CardDef
thePaleMaskBeckons = (treachery "03105" "The Pale Mask Beckons" TheStranger 1)
  { cdCardTraits = setFromList [Omen, Pact]
  }

straitjacket :: CardDef
straitjacket = (treachery "03185" "Straitjacket" TheUnspeakableOath 2)
  { cdCardTraits = setFromList [Item, Clothing]
  }

giftOfMadnessPity :: CardDef
giftOfMadnessPity =
  (treachery "03186" "Gift of Madness (Pity)" TheUnspeakableOath 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

giftOfMadnessMisery :: CardDef
giftOfMadnessMisery =
  (treachery "03187" "Gift of Madness (Misery)" TheUnspeakableOath 1)
    { cdCardTraits = singleton Terror
    , cdKeywords = setFromList [Keyword.Peril, Keyword.Hidden]
    }

wallsClosingIn :: CardDef
wallsClosingIn = (treachery "03188" "Walls Closing In" TheUnspeakableOath 3)
  { cdCardTraits = singleton Terror
  }

theZealotsSeal :: CardDef
theZealotsSeal = (treachery "50024" "The Zealot's Seal" ReturnToTheGathering 2)
  { cdCardTraits = setFromList [Hex]
  }

maskedHorrors :: CardDef
maskedHorrors = (treachery "50031" "Masked Horrors" ReturnToTheMidnightMasks 2)
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
chillFromBelow = (treachery "50040" "Chill from Below" GhoulsOfUmordhoth 3)
  { cdCardTraits = setFromList [Hazard]
  }

maskOfUmordhoth :: CardDef
maskOfUmordhoth = (treachery "50043" "Mask of Umôrdhoth" TheDevourersCult 2)
  { cdCardTraits = setFromList [Item, Mask]
  }

calledByTheMists :: CardDef
calledByTheMists = (weakness "60503" "Called by the Mists")
  { cdCardTraits = setFromList [Curse]
  }

atychiphobia :: CardDef
atychiphobia = (basicWeakness "60504" "Atychiphobia")
  { cdCardTraits = setFromList [Madness]
  }

cursedSwamp :: CardDef
cursedSwamp = (treachery "81024" "Cursed Swamp" TheBayou 3)
  { cdCardTraits = setFromList [Hazard]
  }

spectralMist :: CardDef
spectralMist = (treachery "81025" "Spectral Mist" TheBayou 3)
  { cdCardTraits = setFromList [Hazard]
  }

draggedUnder :: CardDef
draggedUnder = (treachery "81026" "Dragged Under" TheBayou 4)
  { cdCardTraits = setFromList [Hazard]
  }

ripplesOnTheSurface :: CardDef
ripplesOnTheSurface = (treachery "81027" "Ripples on the Surface" TheBayou 3)
  { cdCardTraits = setFromList [Terror]
  }

curseOfTheRougarou :: CardDef
curseOfTheRougarou = (weakness "81029" "Curse of the Rougarou")
  { cdCardTraits = setFromList [Curse]
  , cdEncounterSet = Just CurseOfTheRougarou
  , cdEncounterSetQuantity = Just 1
  }

onTheProwl :: CardDef
onTheProwl = (treachery "81034" "On the Prowl" CurseOfTheRougarou 5)
  { cdKeywords = setFromList [Keyword.Surge]
  }

beastOfTheBayou :: CardDef
beastOfTheBayou = treachery "81035" "Beast of the Bayou" CurseOfTheRougarou 2

insatiableBloodlust :: CardDef
insatiableBloodlust =
  treachery "81036" "Insatiable Bloodlust" CurseOfTheRougarou 3

massHysteria :: CardDef
massHysteria = (treachery "82031" "Mass Hysteria" CarnevaleOfHorrors 3)
  { cdCardTraits = singleton Hazard
  , cdKeywords = singleton Keyword.Peril
  }

lostInVenice :: CardDef
lostInVenice = (treachery "82032" "Lost in Venice" CarnevaleOfHorrors 3)
  { cdCardTraits = singleton Blunder
  , cdKeywords = singleton Keyword.Peril
  }

watchersGaze :: CardDef
watchersGaze = (treachery "82033" "Watchers' Gaze" CarnevaleOfHorrors 3)
  { cdCardTraits = singleton Terror
  }

chaosInTheWater :: CardDef
chaosInTheWater = (treachery "82034" "Chaos in the Water" CarnevaleOfHorrors 3)
  { cdCardTraits = singleton Hazard
  }

mesmerize :: CardDef
mesmerize = (treachery "82035" "Mesmerize" CarnevaleOfHorrors 2)
  { cdCardTraits = singleton Hex
  }

abduction :: CardDef
abduction = (treachery "82036" "Abduction" CarnevaleOfHorrors 2)
  { cdCardTraits = singleton Scheme
  }

acridMiasma :: CardDef
acridMiasma = (treachery "82037" "Acrid Miasma" CarnevaleOfHorrors 2)
  { cdCardTraits = singleton Hazard
  }

module Arkham.Asset.Cards where

import Arkham.Prelude

import Arkham.Types.Asset.Uses hiding (Key)
import Arkham.Types.Card.CardCode
import Arkham.Types.Card.CardDef
import Arkham.Types.Card.CardType
import Arkham.Types.Card.Cost
import Arkham.Types.ClassSymbol
import Arkham.Types.EncounterSet hiding (Dunwich)
import qualified Arkham.Types.Keyword as Keyword
import Arkham.Types.Matcher
import Arkham.Types.Name
import Arkham.Types.SkillType
import Arkham.Types.Trait hiding (Supply)

storyAsset :: CardCode -> Name -> Int -> EncounterSet -> CardDef
storyAsset cardCode name cost encounterSet =
  baseAsset (Just (encounterSet, 1)) cardCode name cost Neutral

storyAssetWithMany :: CardCode -> Name -> Int -> EncounterSet -> Int -> CardDef
storyAssetWithMany cardCode name cost encounterSet encounterSetCount =
  baseAsset (Just (encounterSet, encounterSetCount)) cardCode name cost Neutral

asset :: CardCode -> Name -> Int -> ClassSymbol -> CardDef
asset = baseAsset Nothing

permanent :: CardDef -> CardDef
permanent cd = cd { cdPermanent = True, cdCost = Nothing }

fast :: CardDef -> CardDef
fast cd = cd { cdFastWindow = Just (DuringTurn You) }

weakness :: CardCode -> Name -> CardDef
weakness cardCode name = (baseAsset Nothing cardCode name 0 Neutral)
  { cdCardSubType = Just Weakness
  , cdRevelation = True
  , cdCost = Nothing
  }

storyWeakness :: CardCode -> Name -> EncounterSet -> CardDef
storyWeakness cardCode name encounterSet =
  (baseAsset (Just (encounterSet, 1)) cardCode name 0 Neutral)
    { cdCardSubType = Just Weakness
    , cdRevelation = True
    , cdCost = Nothing
    }

baseAsset
  :: Maybe (EncounterSet, Int)
  -> CardCode
  -> Name
  -> Int
  -> ClassSymbol
  -> CardDef
baseAsset mEncounterSet cardCode name cost classSymbol = CardDef
  { cdCardCode = cardCode
  , cdName = name
  , cdRevealedName = Nothing
  , cdCost = Just (StaticCost cost)
  , cdLevel = 0
  , cdCardType = AssetType
  , cdCardSubType = Nothing
  , cdClassSymbol = Just classSymbol
  , cdSkills = mempty
  , cdCardTraits = mempty
  , cdRevealedCardTraits = mempty
  , cdKeywords = mempty
  , cdFastWindow = Nothing
  , cdAction = Nothing
  , cdRevelation = False
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
  }

allPlayerAssetCards :: HashMap CardCode CardDef
allPlayerAssetCards = mapFromList $ map
  (toCardCode &&& id)
  [ abbessAllegriaDiBiase
  , adaptable1
  , alchemicalTransmutation
  , alyssaGraham
  , analyticalMind
  , aquinnah1
  , aquinnah3
  , arcaneEnlightenment
  , arcaneInitiate
  , arcaneStudies
  , arcaneStudies2
  , archaicGlyphs
  , artStudent
  , bandolier
  , baseballBat
  , beatCop
  , beatCop2
  , blackjack
  , bloodPact3
  , bookOfShadows3
  , brotherXavier1
  , bulletproofVest3
  , burglary
  , catBurglar1
  , celaenoFragments
  , charisma3
  , cherishedKeepsake
  , chicagoTypewriter4
  , clarityOfMind
  , claspOfBlackOnyx
  , combatTraining1
  , daisysToteBag
  , daisysToteBagAdvanced
  , darkHorse
  , davidRenfield
  , digDeep
  , digDeep2
  , discOfItzamna2
  , drFrancisMorgan
  , drHenryArmitage
  , drMilanChristopher
  , drWilliamTMaleson
  , duke
  , earlSawyer
  , elderSignAmulet3
  , encyclopedia
  , encyclopedia2
  , esotericFormula
  , fieldwork
  , fineClothes
  , fireAxe
  , fireExtinguisher1
  , firstAid
  , flashlight
  , forbiddenKnowledge
  , fortyFiveAutomatic
  , fortyOneDerringer
  , gravediggersShovel
  , grotesqueStatue4
  , grounded1
  , guardDog
  , hardKnocks
  , hardKnocks2
  , heirloomOfHyperborea
  , higherEducation
  , higherEducation3
  , hiredMuscle1
  , holyRosary
  , hyperawareness
  , hyperawareness2
  , innocentReveler
  , inTheKnow1
  , jennysTwin45s
  , jewelOfAureolus3
  , jimsTrumpet
  , joeyTheRatVigil
  , keenEye
  , keenEye3
  , knife
  , knuckleduster
  , kukri
  , laboratoryAssistant
  , ladyEsprit
  , lantern
  , leatherCoat
  , leoDeLuca
  , leoDeLuca1
  , lightningGun5
  , liquidCourage
  , litaChantler
  , lockpicks1
  , loneWolf
  , luckyDice2
  , machete
  , magnifyingGlass
  , magnifyingGlass1
  , maskedCarnevaleGoer_17
  , maskedCarnevaleGoer_18
  , maskedCarnevaleGoer_19
  , maskedCarnevaleGoer_20
  , maskedCarnevaleGoer_21
  , medicalTexts
  , monstrousTransformation
  , moxie1
  , newspaper
  , occultLexicon
  , oldBookOfLore
  , painkillers
  , pathfinder1
  , peterSylvestre
  , peterSylvestre2
  , physicalTraining
  , physicalTraining2
  , pickpocketing
  , plucky1
  , policeBadge2
  , powderOfIbnGhazi
  , professorWarrenRice
  , rabbitsFoot
  , rabbitsFoot3
  , relicHunter3
  , researchLibrarian
  , riteOfSeeking
  , riteOfSeeking4
  , ritualCandles
  , rolands38Special
  , scavenging
  , scrapper3
  , scrollOfProphecies
  , scrying
  , shotgun4
  , shrivelling
  , shrivelling3
  , shrivelling5
  , smokingPipe
  , sophieInLovingMemory
  , sophieItWasAllMyFault
  , spiritAthame1
  , stealth
  , streetwise3
  , scientificTheory1
  , songOfTheDead2
  , spiritSpeaker
  , springfieldM19034
  , strangeSolution
  , strangeSolutionAcidicIchor4
  , strangeSolutionFreezingVariant4
  , strangeSolutionRestorativeConcoction4
  , strayCat
  , switchblade
  , switchblade2
  , theGoldPocketWatch4
  , theKingInYellow
  , theNecronomicon
  , theNecronomiconAdvanced
  , theNecronomiconOlausWormiusTranslation
  , theRedGlovedMan5
  , theTatteredCloak
  , thirtyTwoColt
  , toothOfEztli
  , trueGrit
  , tryAndTryAgain3
  , wendysAmulet
  , whittonGreene
  , zebulonWhateley
  , zoeysCross
  ]

allEncounterAssetCards :: HashMap CardCode CardDef
allEncounterAssetCards = mapFromList $ map
  (toCardCode &&& id)
  [ adamLynch
  , alchemicalConcoction
  , bearTrap
  , fishingNet
  , haroldWalsted
  , helplessPassenger
  , jazzMulligan
  , keyToTheChamber
  , peterClover
  , constanceDumaine
  , jordanPerry
  , ishimaruHaruko
  , sebastienMoreau
  , ashleighClarke
  , mrPeabody
  ]

rolands38Special :: CardDef
rolands38Special = (asset "01006" "Roland's .38 Special" 3 Neutral)
  { cdSkills = [SkillCombat, SkillAgility, SkillWild]
  , cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdUnique = True
  , cdUses = Uses Ammo 4
  }

daisysToteBag :: CardDef
daisysToteBag = (asset "01008" "Daisy's Tote Bag" 2 Neutral)
  { cdSkills = [SkillWillpower, SkillIntellect, SkillWild]
  , cdCardTraits = setFromList [Item]
  , cdUnique = True
  }

theNecronomicon :: CardDef
theNecronomicon =
  (weakness "01009" ("The Necronomicon" <:> "John Dee Translation"))
    { cdCardTraits = setFromList [Item, Tome]
    }

heirloomOfHyperborea :: CardDef
heirloomOfHyperborea = (asset
                         "01012"
                         ("Heirloom of Hyperborea"
                         <:> "Artifact from Another Life"
                         )
                         3
                         Neutral
                       )
  { cdSkills = [SkillWillpower, SkillCombat, SkillWild]
  , cdCardTraits = setFromList [Item, Relic]
  , cdUnique = True
  }

wendysAmulet :: CardDef
wendysAmulet = (asset "01014" "Wendy's Amulet" 2 Neutral)
  { cdSkills = [SkillWild, SkillWild]
  , cdCardTraits = setFromList [Item, Relic]
  , cdUnique = True
  }

fortyFiveAutomatic :: CardDef
fortyFiveAutomatic = (asset "01016" ".45 Automatic" 4 Guardian)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdUses = Uses Ammo 4
  }

physicalTraining :: CardDef
physicalTraining = (asset "01017" "Physical Training" 2 Guardian)
  { cdSkills = [SkillWillpower, SkillCombat]
  , cdCardTraits = setFromList [Talent]
  }

beatCop :: CardDef
beatCop = (asset "01018" "Beat Cop" 4 Guardian)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Ally, Police]
  }

firstAid :: CardDef
firstAid = (asset "01019" "First Aid" 2 Guardian)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Talent, Science]
  , cdUses = Uses Supply 3
  }

machete :: CardDef
machete = (asset "01020" "Machete" 3 Guardian)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Melee]
  }

guardDog :: CardDef
guardDog = (asset "01021" "Guard Dog" 3 Guardian)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Ally, Creature]
  }

policeBadge2 :: CardDef
policeBadge2 = (asset "01027" "Police Badge" 3 Guardian)
  { cdSkills = [SkillWillpower, SkillWild]
  , cdCardTraits = setFromList [Item]
  , cdLevel = 2
  }

beatCop2 :: CardDef
beatCop2 = (asset "01028" "Beat Cop" 4 Guardian)
  { cdSkills = [SkillCombat, SkillAgility]
  , cdCardTraits = setFromList [Ally, Police]
  , cdLevel = 2
  }

shotgun4 :: CardDef
shotgun4 = (asset "01029" "Shotgun" 5 Guardian)
  { cdSkills = [SkillCombat, SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdLevel = 4
  , cdUses = Uses Ammo 2
  }

magnifyingGlass :: CardDef
magnifyingGlass = fast $ (asset "01030" "Magnifying Glass" 1 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tool]
  }

oldBookOfLore :: CardDef
oldBookOfLore = (asset "01031" "Old Book of Lore" 3 Seeker)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Item, Tome]
  }

researchLibrarian :: CardDef
researchLibrarian = (asset "01032" "Research Librarian" 2 Seeker)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Ally, Miskatonic]
  }

drMilanChristopher :: CardDef
drMilanChristopher =
  (asset
      "01033"
      ("Dr. Milan Christopher" <:> "Professor of Entomology")
      4
      Seeker
    )
    { cdSkills = [SkillIntellect]
    , cdCardTraits = setFromList [Ally, Miskatonic]
    , cdUnique = True
    }

hyperawareness :: CardDef
hyperawareness = (asset "01034" "Hyperawareness" 2 Seeker)
  { cdSkills = [SkillIntellect, SkillAgility]
  , cdCardTraits = setFromList [Talent]
  }

medicalTexts :: CardDef
medicalTexts = (asset "01035" "Medical Texts" 2 Seeker)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Tome]
  }

magnifyingGlass1 :: CardDef
magnifyingGlass1 = fast $ (asset "01040" "Magnifying Glass" 0 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tool]
  , cdLevel = 1
  }

discOfItzamna2 :: CardDef
discOfItzamna2 =
  (asset "01041" ("Disc of Itzamna" <:> "Protective Amulet") 3 Seeker)
    { cdSkills = [SkillWillpower, SkillIntellect, SkillCombat]
    , cdCardTraits = setFromList [Item, Relic]
    , cdLevel = 2
    , cdUnique = True
    }

encyclopedia2 :: CardDef
encyclopedia2 = (asset "01042" "Encyclopedia" 2 Seeker)
  { cdSkills = [SkillWild]
  , cdCardTraits = setFromList [Item, Tome]
  , cdLevel = 2
  }

switchblade :: CardDef
switchblade = fast $ (asset "01044" "Switchblade" 1 Rogue)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Item, Weapon, Melee, Illicit]
  }

burglary :: CardDef
burglary = (asset "01045" "Burglary" 1 Rogue)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Talent, Illicit]
  }

pickpocketing :: CardDef
pickpocketing = (asset "01046" "Pickpocketing" 2 Rogue)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Talent, Illicit]
  }

fortyOneDerringer :: CardDef
fortyOneDerringer = (asset "01047" ".41 Derringer" 3 Rogue)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Firearm, Illicit]
  , cdUses = Uses Ammo 3
  }

leoDeLuca :: CardDef
leoDeLuca = (asset "01048" ("Leo De Luca" <:> "The Louisiana Lion") 6 Rogue)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Ally, Criminal]
  , cdUnique = True
  }

hardKnocks :: CardDef
hardKnocks = (asset "01049" "Hard Knocks" 2 Rogue)
  { cdSkills = [SkillCombat, SkillAgility]
  , cdCardTraits = setFromList [Talent]
  }

leoDeLuca1 :: CardDef
leoDeLuca1 = (asset "01054" ("Leo De Luca" <:> "The Louisiana Lion") 5 Rogue)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Ally, Criminal]
  , cdLevel = 1
  , cdUnique = True
  }

catBurglar1 :: CardDef
catBurglar1 = (asset "01055" "Cat Burglar" 4 Rogue)
  { cdSkills = [SkillWillpower, SkillAgility]
  , cdCardTraits = setFromList [Ally, Criminal]
  , cdLevel = 1
  }

forbiddenKnowledge :: CardDef
forbiddenKnowledge = (asset "01058" "Forbidden Knowledge" 0 Mystic)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Talent]
  , cdUses = Uses Secret 4
  }

holyRosary :: CardDef
holyRosary = (asset "01059" "Holy Rosary" 2 Mystic)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Item, Charm]
  }

shrivelling :: CardDef
shrivelling = (asset "01060" "Shrivelling" 3 Mystic)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Spell]
  , cdUses = Uses Charge 4
  }

scrying :: CardDef
scrying = (asset "01061" "Scrying" 1 Mystic)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Spell]
  , cdUses = Uses Charge 3
  }

arcaneStudies :: CardDef
arcaneStudies = (asset "01062" "Arcane Studies" 2 Mystic)
  { cdSkills = [SkillWillpower, SkillIntellect]
  , cdCardTraits = setFromList [Talent]
  }

arcaneInitiate :: CardDef
arcaneInitiate = (asset "01063" "Arcane Initiate" 1 Mystic)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Ally, Sorcerer]
  }

bookOfShadows3 :: CardDef
bookOfShadows3 = (asset "01070" "Book of Shadows" 4 Mystic)
  { cdSkills = [SkillWillpower, SkillIntellect]
  , cdCardTraits = setFromList [Item, Tome]
  , cdLevel = 3
  }

grotesqueStatue4 :: CardDef
grotesqueStatue4 = (asset "01071" "Grotesque Statue" 2 Mystic)
  { cdSkills = [SkillWild]
  , cdCardTraits = setFromList [Item, Relic]
  , cdLevel = 4
  , cdUses = Uses Charge 4
  }

leatherCoat :: CardDef
leatherCoat = (asset "01072" "Leather Coat" 0 Survivor)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Armor]
  }

scavenging :: CardDef
scavenging = (asset "01073" "Scavenging" 1 Survivor)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Talent]
  }

baseballBat :: CardDef
baseballBat = (asset "01074" "Baseball Bat" 2 Survivor)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Melee]
  }

rabbitsFoot :: CardDef
rabbitsFoot = (asset "01075" "Rabbit's Foot" 1 Survivor)
  { cdSkills = [SkillWild]
  , cdCardTraits = setFromList [Item, Charm]
  }

strayCat :: CardDef
strayCat = (asset "01076" "Stray Cat" 1 Survivor)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Ally, Creature]
  }

digDeep :: CardDef
digDeep = (asset "01077" "Dig Deep" 2 Survivor)
  { cdSkills = [SkillWillpower, SkillAgility]
  , cdCardTraits = setFromList [Talent]
  }

aquinnah1 :: CardDef
aquinnah1 = (asset "01082" ("Aquinnah" <:> "The Forgotten Daughter") 5 Survivor
            )
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Ally]
  , cdLevel = 1
  , cdUnique = True
  }

knife :: CardDef
knife = (asset "01086" "Knife" 1 Neutral)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Melee]
  }

flashlight :: CardDef
flashlight = (asset "01087" "Flashlight" 2 Neutral)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tool]
  , cdUses = Uses Supply 3
  }

bulletproofVest3 :: CardDef
bulletproofVest3 = (asset "01094" "Bulletproof Vest" 2 Neutral)
  { cdSkills = [SkillCombat, SkillWild]
  , cdCardTraits = setFromList [Item, Armor]
  , cdLevel = 3
  }

elderSignAmulet3 :: CardDef
elderSignAmulet3 = (asset "01095" "Elder Sign Amulet" 2 Neutral)
  { cdSkills = [SkillWillpower, SkillWild]
  , cdCardTraits = setFromList [Item, Relic]
  , cdLevel = 3
  }

litaChantler :: CardDef
litaChantler =
  (storyAsset "01117" ("Lita Chantler" <:> "The Zealot") 0 TheGathering)
    { cdCardTraits = setFromList [Ally]
    , cdUnique = True
    }

zoeysCross :: CardDef
zoeysCross =
  (asset "02006" ("Zoey's Cross" <:> "Symbol of Righteousness") 1 Neutral)
    { cdSkills = [SkillCombat, SkillCombat, SkillWild]
    , cdCardTraits = setFromList [Item, Charm]
    , cdUnique = True
    }

jennysTwin45s :: CardDef
jennysTwin45s =
  (asset "02010" ("Jenny's Twin .45s" <:> "A Perfect Fit") 0 Neutral)
    { cdSkills = [SkillAgility, SkillAgility, SkillWild]
    , cdCardTraits = setFromList [Item, Weapon, Firearm]
    , cdCost = Just DynamicCost
    , cdUnique = True
    }

jimsTrumpet :: CardDef
jimsTrumpet = (asset "02012" ("Jim's Trumpet" <:> "The Dead Listen") 2 Neutral)
  { cdSkills = [SkillWillpower, SkillWillpower, SkillWild]
  , cdCardTraits = setFromList [Item, Instrument, Relic]
  , cdUnique = True
  }

duke :: CardDef
duke = (asset "02014" ("Duke" <:> "Loyal Hound") 2 Neutral)
  { cdCardTraits = setFromList [Ally, Creature]
  , cdUnique = True
  }

blackjack :: CardDef
blackjack = (asset "02016" "Blackjack" 1 Guardian)
  { cdCardTraits = setFromList [Item, Weapon, Melee]
  , cdSkills = [SkillCombat]
  }

laboratoryAssistant :: CardDef
laboratoryAssistant = (asset "02020" "Laboratory Assistant" 2 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Ally, Miskatonic, Science]
  }

strangeSolution :: CardDef
strangeSolution =
  (asset "02021" ("Strange Solution" <:> "Unidentified") 1 Seeker)
    { cdSkills = [SkillWild]
    , cdCardTraits = setFromList [Item, Science]
    }

liquidCourage :: CardDef
liquidCourage = (asset "02024" "Liquid Courage" 1 Rogue)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Item, Illicit]
  , cdUses = Uses Supply 4
  }

hiredMuscle1 :: CardDef
hiredMuscle1 = (asset "02027" "Hired Muscle" 1 Rogue)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Ally, Criminal]
  , cdLevel = 1
  }

riteOfSeeking :: CardDef
riteOfSeeking = (asset "02028" "Rite of Seeking" 4 Mystic)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Spell]
  , cdUses = Uses Charge 3
  }

ritualCandles :: CardDef
ritualCandles = (asset "02029" "Ritual Candles" 1 Mystic)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = singleton Item
  }

clarityOfMind :: CardDef
clarityOfMind = (asset "02030" "Clarity of Mind" 2 Mystic)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = singleton Spell
  , cdUses = Uses Charge 3
  }

fireAxe :: CardDef
fireAxe = (asset "02032" "Fire Axe" 1 Survivor)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Melee]
  }

peterSylvestre :: CardDef
peterSylvestre =
  (asset "02033" ("Peter Sylvestre" <:> "Big Man on Campus") 3 Survivor)
    { cdSkills = [SkillWillpower]
    , cdCardTraits = setFromList [Ally, Miskatonic]
    , cdUnique = True
    }

peterSylvestre2 :: CardDef
peterSylvestre2 =
  (asset "02035" ("Peter Sylvestre" <:> "Big Man on Campus") 3 Survivor)
    { cdSkills = [SkillWillpower]
    , cdCardTraits = setFromList [Ally, Miskatonic]
    , cdLevel = 2
    , cdUnique = True
    }

kukri :: CardDef
kukri = (asset "02036" "Kukri" 2 Neutral)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Melee]
  }

drHenryArmitage :: CardDef
drHenryArmitage = (storyAsset
                    "02040"
                    ("Dr. Henry Armitage" <:> "The Head Librarian")
                    2
                    ArmitagesFate
                  )
  { cdSkills = [SkillWild, SkillWild]
  , cdCardTraits = setFromList [Ally, Miskatonic]
  , cdUnique = True
  }

alchemicalConcoction :: CardDef
alchemicalConcoction =
  (storyAsset "02059" "Alchemical Concoction" 0 ExtracurricularActivity)
    { cdCardTraits = setFromList [Item, Science]
    , cdCardType = EncounterAssetType
    }

jazzMulligan :: CardDef
jazzMulligan = (storyAsset
                 "02060"
                 ("\"Jazz\" Mulligan" <:> "The Head Janitor")
                 0
                 ExtracurricularActivity
               )
  { cdCardTraits = setFromList [Ally, Miskatonic]
  , cdUnique = True
  , cdCardType = EncounterAssetType
  }

professorWarrenRice :: CardDef
professorWarrenRice = (storyAsset
                        "02061"
                        ("Professor Warren Rice" <:> "Professor of Languages")
                        3
                        ExtracurricularActivity
                      )
  { cdSkills = [SkillIntellect, SkillWild]
  , cdCardTraits = setFromList [Ally, Miskatonic]
  , cdUnique = True
  }

peterClover :: CardDef
peterClover = (storyAsset
                "02079"
                ("Peter Clover" <:> "Holding All the Cards")
                0
                TheHouseAlwaysWins
              )
  { cdCardTraits = setFromList [Humanoid, Criminal]
  , cdUnique = True
  }

drFrancisMorgan :: CardDef
drFrancisMorgan = (storyAsset
                    "02080"
                    ("Dr. Francis Morgan" <:> "Professor of Archaeology")
                    3
                    TheHouseAlwaysWins
                  )
  { cdSkills = [SkillCombat, SkillWild]
  , cdCardTraits = setFromList [Ally, Miskatonic]
  , cdUnique = True
  }

brotherXavier1 :: CardDef
brotherXavier1 =
  (asset "02106" ("Brother Xavier" <:> "Pure of Spirit") 5 Guardian)
    { cdSkills = [SkillWillpower]
    , cdCardTraits = setFromList [Ally]
    , cdLevel = 1
    , cdUnique = True
    }

pathfinder1 :: CardDef
pathfinder1 = (asset "02108" "Pathfinder" 3 Seeker)
  { cdSkills = [SkillAgility]
  , cdCardTraits = singleton Talent
  , cdLevel = 1
  }

adaptable1 :: CardDef
adaptable1 = permanent $ (asset "02110" "Adaptable" 0 Rogue)
  { cdCardTraits = setFromList [Talent]
  , cdLevel = 1
  }

songOfTheDead2 :: CardDef
songOfTheDead2 = (asset "02112" "Song of the Dead" 2 Mystic)
  { cdCardTraits = setFromList [Spell, Song]
  , cdSkills = [SkillWillpower]
  , cdLevel = 2
  , cdUses = Uses Charge 5
  }

fireExtinguisher1 :: CardDef
fireExtinguisher1 = (asset "02114" "Fire Extinguisher" 2 Survivor)
  { cdCardTraits = setFromList [Item, Tool, Melee]
  , cdSkills = [SkillAgility]
  , cdLevel = 1
  }

smokingPipe :: CardDef
smokingPipe = (asset "02116" "Smoking Pipe" 1 Neutral)
  { cdCardTraits = singleton Item
  , cdSkills = [SkillWillpower]
  , cdUses = Uses Supply 3
  }

painkillers :: CardDef
painkillers = (asset "02117" "Painkillers" 1 Neutral)
  { cdCardTraits = singleton Item
  , cdSkills = [SkillWillpower]
  , cdUses = Uses Supply 3
  }

haroldWalsted :: CardDef
haroldWalsted = (storyAsset
                  "02138"
                  ("Harold Walsted" <:> "Curator of the Museum")
                  0
                  TheMiskatonicMuseum
                )
  { cdCardTraits = setFromList [Ally, Miskatonic]
  , cdUnique = True
  , cdCardType = EncounterAssetType
  }

adamLynch :: CardDef
adamLynch =
  (storyAsset "02139" ("Adam Lynch" <:> "Museum Security") 0 TheMiskatonicMuseum
    )
    { cdCardTraits = setFromList [Ally, Miskatonic]
    , cdUnique = True
    }

artStudent :: CardDef
artStudent = (asset "02149" "Art Student" 2 Seeker)
  { cdCardTraits = setFromList [Ally, Miskatonic]
  , cdSkills = [SkillIntellect]
  }

switchblade2 :: CardDef
switchblade2 = fast $ (asset "02152" "Switchblade" 1 Rogue)
  { cdSkills = [SkillCombat, SkillAgility]
  , cdCardTraits = setFromList [Item, Weapon, Melee, Illicit]
  , cdLevel = 2
  }

shrivelling3 :: CardDef
shrivelling3 = (asset "02154" "Shrivelling" 3 Mystic)
  { cdSkills = [SkillWillpower, SkillCombat]
  , cdCardTraits = singleton Spell
  , cdLevel = 3
  , cdUses = Uses Charge 4
  }

newspaper :: CardDef
newspaper = (asset "02155" "Newspaper" 1 Survivor)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = singleton Item
  }

relicHunter3 :: CardDef
relicHunter3 = permanent $ (asset "02157" "Relic Hunter" 0 Neutral)
  { cdCardTraits = singleton Talent
  , cdLevel = 3
  }

charisma3 :: CardDef
charisma3 = permanent $ (asset "02158" "Charisma" 0 Neutral)
  { cdCardTraits = singleton Talent
  , cdLevel = 3
  }

theNecronomiconOlausWormiusTranslation :: CardDef
theNecronomiconOlausWormiusTranslation =
  (storyAsset
      "02140"
      ("The Necronomicon" <:> "Olaus Wormius Translation")
      2
      TheMiskatonicMuseum
    )
    { cdSkills = [SkillIntellect]
    , cdCardTraits = setFromList [Item, Tome]
    }

bandolier :: CardDef
bandolier = (asset "02147" "Bandolier" 2 Guardian)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item]
  }

helplessPassenger :: CardDef
helplessPassenger =
  (storyAsset "02179" "Helpless Passenger" 0 TheEssexCountyExpress)
    { cdCardTraits = setFromList [Ally, Bystander]
    , cdKeywords = singleton Keyword.Surge
    , cdEncounterSetQuantity = Just 3
    }

keenEye3 :: CardDef
keenEye3 = permanent $ (asset "02185" "Keen Eye" 0 Guardian)
  { cdCardTraits = setFromList [Talent]
  , cdLevel = 3
  }

higherEducation3 :: CardDef
higherEducation3 = permanent $ (asset "02187" "Higher Education" 0 Seeker)
  { cdCardTraits = setFromList [Talent]
  , cdLevel = 3
  }

loneWolf :: CardDef
loneWolf = (asset "02188" "Lone Wolf" 1 Rogue)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Talent]
  , cdLimits = [LimitPerInvestigator 1]
  }

streetwise3 :: CardDef
streetwise3 = permanent $ (asset "02189" "Streetwise" 0 Rogue)
  { cdCardTraits = setFromList [Talent]
  , cdLevel = 3
  }

bloodPact3 :: CardDef
bloodPact3 = permanent $ (asset "02191" "Blood Pact" 0 Mystic)
  { cdCardTraits = setFromList [Spell, Pact]
  , cdLevel = 3
  }

scrapper3 :: CardDef
scrapper3 = permanent $ (asset "02193" "Scrapper" 0 Survivor)
  { cdCardTraits = setFromList [Talent]
  , cdLevel = 3
  }

keyToTheChamber :: CardDef
keyToTheChamber = (storyAsset "02215" "Key to the Chamber" 0 BloodOnTheAltar)
  { cdCardTraits = setFromList [Item, Key]
  , cdUnique = True
  , cdCardType = EncounterAssetType
  }

zebulonWhateley :: CardDef
zebulonWhateley = (storyAsset
                    "02217"
                    ("Zebulon Whateley" <:> "Recalling Ancient Things")
                    3
                    BloodOnTheAltar
                  )
  { cdCardTraits = setFromList [Ally, Dunwich]
  , cdSkills = [SkillWillpower, SkillWild]
  , cdUnique = True
  }

earlSawyer :: CardDef
earlSawyer = (storyAsset
               "02218"
               ("Earl Sawyer" <:> "Smarter Than He Lets On")
               3
               BloodOnTheAltar
             )
  { cdCardTraits = setFromList [Ally, Dunwich]
  , cdSkills = [SkillAgility, SkillWild]
  , cdUnique = True
  }

powderOfIbnGhazi :: CardDef
powderOfIbnGhazi = (storyAsset
                     "02219"
                     ("Powder of Ibn-Ghazi" <:> "Seeing Things Unseen")
                     0
                     BloodOnTheAltar
                   )
  { cdCardTraits = singleton Item
  }

springfieldM19034 :: CardDef
springfieldM19034 = (asset "02226" "Springfield M1903" 4 Guardian)
  { cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdLevel = 4
  , cdSkills = [SkillCombat, SkillAgility]
  , cdUses = Uses Ammo 3
  }

luckyDice2 :: CardDef
luckyDice2 = (asset "02230" ("Lucky Dice" <:> "... Or Are They?") 2 Rogue)
  { cdCardTraits = setFromList [Item, Relic]
  , cdSkills = [SkillWillpower, SkillAgility]
  , cdExceptional = True
  , cdLevel = 2
  }

alyssaGraham :: CardDef
alyssaGraham =
  (asset "02232" ("Alyssa Graham" <:> "Speaker to the Dead") 4 Mystic)
    { cdCardTraits = setFromList [Ally, Sorcerer]
    , cdSkills = [SkillIntellect]
    , cdUnique = True
    }

riteOfSeeking4 :: CardDef
riteOfSeeking4 = (asset "02233" "Rite of Seeking" 5 Mystic)
  { cdCardTraits = singleton Spell
  , cdSkills = [SkillIntellect, SkillIntellect]
  , cdLevel = 4
  , cdUses = Uses Charge 3
  }

darkHorse :: CardDef
darkHorse = (asset "02234" "Dark Horse" 3 Survivor)
  { cdCardTraits = singleton Condition
  , cdSkills = [SkillWillpower]
  , cdLimits = [LimitPerInvestigator 1]
  }

esotericFormula :: CardDef
esotericFormula =
  (storyAsset "02254" "Esoteric Formula" 0 UndimensionedAndUnseen)
    { cdCardTraits = singleton Spell
    , cdEncounterSetQuantity = Just 4
    }

strangeSolutionRestorativeConcoction4 :: CardDef
strangeSolutionRestorativeConcoction4 =
  (asset "02262" ("Strange Solution" <:> "Restorative Concoction") 1 Seeker)
    { cdCardTraits = setFromList [Item, Science]
    , cdSkills = [SkillWillpower, SkillWillpower]
    , cdLevel = 4
    , cdUses = Uses Supply 4
    }

strangeSolutionAcidicIchor4 :: CardDef
strangeSolutionAcidicIchor4 =
  (asset "02263" ("Strange Solution" <:> "Acidic Ichor") 1 Seeker)
    { cdCardTraits = setFromList [Item, Science]
    , cdSkills = [SkillCombat, SkillCombat]
    , cdLevel = 4
    , cdUses = Uses Supply 4
    }

strangeSolutionFreezingVariant4 :: CardDef
strangeSolutionFreezingVariant4 =
  (asset "02264" ("Strange Solution" <:> "Freezing Variant") 1 Seeker)
    { cdCardTraits = setFromList [Item, Science]
    , cdSkills = [SkillAgility, SkillAgility]
    , cdLevel = 4
    , cdUses = Uses Supply 4
    }

joeyTheRatVigil :: CardDef
joeyTheRatVigil =
  (asset "02265" ("Joey \"The Rat\" Vigil" <:> "Lookin' Out for #1") 4 Rogue)
    { cdCardTraits = setFromList [Ally, Criminal]
    , cdSkills = [SkillIntellect, SkillAgility]
    , cdUnique = True
    }

jewelOfAureolus3 :: CardDef
jewelOfAureolus3 =
  (asset "02269" ("Jewel of Aureolus" <:> "Gift of the Homunculi") 3 Mystic)
    { cdCardTraits = setFromList [Item, Relic]
    , cdSkills = [SkillWild]
    , cdLevel = 3
    , cdUnique = True
    }

fineClothes :: CardDef
fineClothes = (asset "02272" "Fine Clothes" 1 Neutral)
  { cdCardTraits = setFromList [Item, Clothing]
  , cdSkills = [SkillAgility]
  }

lightningGun5 :: CardDef
lightningGun5 = (asset "02301" "Lightning Gun" 6 Guardian)
  { cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdLevel = 5
  , cdSkills = [SkillIntellect, SkillCombat]
  , cdUses = Uses Ammo 3
  }

drWilliamTMaleson :: CardDef
drWilliamTMaleson = (asset
                      "02302"
                      ("Dr. William T. Maleson" <:> "Working on Something Big")
                      1
                      Seeker
                    )
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Ally, Miskatonic]
  , cdUnique = True
  }

chicagoTypewriter4 :: CardDef
chicagoTypewriter4 = (asset "02304" "Chicago Typewriter" 5 Rogue)
  { cdSkills = [SkillCombat, SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Firearm, Illicit]
  , cdLevel = 4
  , cdUses = Uses Ammo 4
  }

theGoldPocketWatch4 :: CardDef
theGoldPocketWatch4 =
  (asset "02305" ("The Gold Pocket Watch" <:> "Stealing Time") 2 Rogue)
    { cdSkills = [SkillWillpower, SkillWild]
    , cdCardTraits = setFromList [Item, Relic]
    , cdLevel = 4
    , cdUnique = True
    , cdExceptional = True
    }

shrivelling5 :: CardDef
shrivelling5 = (asset "02306" "Shrivelling" 3 Mystic)
  { cdSkills = [SkillWillpower, SkillCombat, SkillCombat]
  , cdCardTraits = singleton Spell
  , cdLevel = 5
  , cdUses = Uses Charge 4
  }


aquinnah3 :: CardDef
aquinnah3 = (asset "02308" ("Aquinnah" <:> "The Forgotten Daughter") 4 Survivor
            )
  { cdSkills = [SkillWillpower, SkillAgility]
  , cdCardTraits = setFromList [Ally]
  , cdLevel = 3
  , cdUnique = True
  }

tryAndTryAgain3 :: CardDef
tryAndTryAgain3 = (asset "02309" "Try and Try Again" 2 Survivor)
  { cdSkills = [SkillWillpower, SkillWillpower]
  , cdCardTraits = singleton Talent
  , cdLevel = 3
  }

theRedGlovedMan5 :: CardDef
theRedGlovedMan5 =
  fast
    $ (asset "02310" ("The Red-Gloved Man" <:> "He Was Never There") 2 Neutral)
        { cdSkills = [SkillWild]
        , cdCardTraits = setFromList [Ally, Conspirator]
        , cdLevel = 5
        , cdUnique = True
        }

sophieInLovingMemory :: CardDef
sophieInLovingMemory =
  (asset "03009" ("Sophie" <:> "In Loving Memory") 0 Neutral)
    { cdCardTraits = setFromList [Item, Spirit]
    , cdUnique = True
    , cdCost = Nothing
    }

sophieItWasAllMyFault :: CardDef
sophieItWasAllMyFault =
  (asset "03009b" ("Sophie" <:> "It Was All My Fault") 0 Neutral)
    { cdCardTraits = setFromList [Item, Madness]
    , cdUnique = True
    , cdCost = Nothing
    }

analyticalMind :: CardDef
analyticalMind =
  (asset "03010" ("Analytical Mind" <:> "Between the Lines") 3 Neutral)
    { cdCardTraits = singleton Talent
    , cdSkills = [SkillWild, SkillWild]
    }

theKingInYellow :: CardDef
theKingInYellow = (weakness "03011" ("The King in Yellow" <:> "Act 1"))
  { cdCardTraits = singleton Tome
  , cdUnique = True
  }

spiritSpeaker :: CardDef
spiritSpeaker =
  (asset "03014" ("Spirit-Speaker" <:> "Envoy of the Alusi") 2 Neutral)
    { cdSkills = [SkillWillpower, SkillIntellect, SkillWild]
    , cdCardTraits = singleton Ritual
    }

thirtyTwoColt :: CardDef
thirtyTwoColt = (asset "03020" ".32 Colt" 3 Guardian)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdUses = Uses Ammo 6
  }

trueGrit :: CardDef
trueGrit = (asset "03021" "True Grit" 3 Guardian)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = singleton Talent
  }

fieldwork :: CardDef
fieldwork = (asset "03024" "Fieldwork" 2 Seeker)
  { cdSkills = [SkillAgility]
  , cdCardTraits = singleton Talent
  }

archaicGlyphs :: CardDef
archaicGlyphs = (asset "03025" ("Archaic Glyphs" <:> "Untranslated") 0 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Occult, Tome]
  }

inTheKnow1 :: CardDef
inTheKnow1 = (asset "03027" "In the Know" 3 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = singleton Talent
  , cdUses = Uses Secret 3
  , cdLevel = 1
  }

stealth :: CardDef
stealth = (asset "03028" "Stealth" 2 Rogue)
  { cdSkills = [SkillAgility]
  , cdCardTraits = singleton Talent
  }

lockpicks1 :: CardDef
lockpicks1 = (asset "03031" "Lockpicks" 3 Rogue)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tool, Illicit]
  , cdUses = Uses Supply 3
  , cdLevel = 1
  }

alchemicalTransmutation :: CardDef
alchemicalTransmutation = (asset "03032" "Alchemical Transmutation" 1 Mystic)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = singleton Spell
  , cdUses = Uses Charge 3
  }

spiritAthame1 :: CardDef
spiritAthame1 = (asset "03035" "Spirit Athame" 3 Mystic)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Relic, Weapon, Melee]
  , cdLevel = 1
  }

lantern :: CardDef
lantern = (asset "03036" "Lantern" 2 Survivor)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tool]
  }

gravediggersShovel :: CardDef
gravediggersShovel = (asset "03037" "Gravedigger's Shovel" 2 Survivor)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Tool, Weapon, Melee]
  }

constanceDumaine :: CardDef
constanceDumaine =
  (storyAsset "03076" ("Constance Dumaine" <:> "Sociable Hostess") 0 TheLastKing
    )
    { cdCardTraits = singleton Bystander
    , cdUnique = True
    , cdCardType = EncounterAssetType
    , cdDoubleSided = True
    , cdCost = Nothing
    }

jordanPerry :: CardDef
jordanPerry =
  (storyAsset "03077" ("Jordan Perry" <:> "Dignified Financier") 0 TheLastKing)
    { cdCardTraits = singleton Bystander
    , cdUnique = True
    , cdCardType = EncounterAssetType
    , cdDoubleSided = True
    , cdCost = Nothing
    }

ishimaruHaruko :: CardDef
ishimaruHaruko =
  (storyAsset "03078" ("Ishimaru Haruko" <:> "Costume Designer") 0 TheLastKing)
    { cdCardTraits = singleton Bystander
    , cdUnique = True
    , cdCardType = EncounterAssetType
    , cdDoubleSided = True
    , cdCost = Nothing
    }

sebastienMoreau :: CardDef
sebastienMoreau = (storyAsset
                    "03079"
                    ("Sebastien Moreau" <:> "Impassioned Producer")
                    0
                    TheLastKing
                  )
  { cdCardTraits = singleton Bystander
  , cdUnique = True
  , cdCardType = EncounterAssetType
  , cdDoubleSided = True
  , cdCost = Nothing
  }

ashleighClarke :: CardDef
ashleighClarke = (storyAsset
                   "03080"
                   ("Ashleigh Clarke" <:> "Talented Entertainer")
                   0
                   TheLastKing
                 )
  { cdCardTraits = singleton Bystander
  , cdUnique = True
  , cdCardType = EncounterAssetType
  , cdDoubleSided = True
  , cdCost = Nothing
  }

combatTraining1 :: CardDef
combatTraining1 = (asset "03107" "Combat Training" 1 Guardian)
  { cdSkills = [SkillCombat, SkillAgility]
  , cdCardTraits = setFromList [Talent, Composure]
  , cdLimits = [LimitPerTrait Composure 1]
  , cdLevel = 1
  }

scientificTheory1 :: CardDef
scientificTheory1 = (asset "03109" "Scientific Theory" 1 Seeker)
  { cdSkills = [SkillIntellect, SkillCombat]
  , cdCardTraits = setFromList [Talent, Composure]
  , cdLimits = [LimitPerTrait Composure 1]
  , cdLevel = 1
  }

knuckleduster :: CardDef
knuckleduster = (asset "03110" "Knuckleduster" 2 Rogue)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Melee, Illicit]
  }

moxie1 :: CardDef
moxie1 = (asset "03111" "Moxie" 1 Rogue)
  { cdSkills = [SkillWillpower, SkillAgility]
  , cdCardTraits = setFromList [Talent, Composure]
  , cdLimits = [LimitPerTrait Composure 1]
  , cdLevel = 1
  }

davidRenfield :: CardDef
davidRenfield =
  (asset "03112" ("David Renfield" <:> "Esteemed Eschatologist") 2 Mystic)
    { cdSkills = [SkillIntellect]
    , cdCardTraits = setFromList [Ally, Patron]
    , cdUnique = True
    }

grounded1 :: CardDef
grounded1 = (asset "03113" "Grounded" 1 Mystic)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Talent, Composure]
  , cdLimits = [LimitPerTrait Composure 1]
  , cdLevel = 1
  }

cherishedKeepsake :: CardDef
cherishedKeepsake = (asset "03114" "Cherished Keepsake" 0 Survivor)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Item, Charm]
  }

plucky1 :: CardDef
plucky1 = (asset "03115" "Plucky" 1 Survivor)
  { cdSkills = [SkillWillpower, SkillIntellect]
  , cdCardTraits = setFromList [Talent, Composure]
  , cdLimits = [LimitPerTrait Composure 1]
  , cdLevel = 1
  }

mrPeabody :: CardDef
mrPeabody = (storyAsset
              "03141"
              ("Mr. Peabody" <:> "Historical Society Curator")
              0
              EchoesOfThePast
            )
  { cdCardTraits = setFromList [Ally, HistoricalSociety]
  , cdUnique = True
  , cdCardType = EncounterAssetType
  }

claspOfBlackOnyx :: CardDef
claspOfBlackOnyx = (storyWeakness
                     "03142"
                     ("Clasp of Black Onyx" <:> "A Gift Unlooked For")
                     EchoesOfThePast
                   )
  { cdSkills = [SkillWillpower, SkillCombat, SkillAgility]
  , cdCardTraits = setFromList [Item, Clothing]
  , cdCost = Just (StaticCost 1)
  , cdRevelation = False
  }

theTatteredCloak :: CardDef
theTatteredCloak = (storyAsset
                     "03143"
                     ("The Tattered Cloak" <:> "Regalia Dementia")
                     2
                     EchoesOfThePast
                   )
  { cdSkills = [SkillWillpower, SkillCombat, SkillAgility]
  , cdCardTraits = setFromList [Item, Clothing]
  }

toothOfEztli :: CardDef
toothOfEztli = (asset "04023" ("Tooth of Eztli" <:> "Mortal Reminder") 3 Seeker
               )
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Item, Relic]
  }

occultLexicon :: CardDef
occultLexicon = (asset "05316" "Occult Lexicon" 2 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tome, Occult]
  }

scrollOfProphecies :: CardDef
scrollOfProphecies = (asset "06116" "Scroll of Prophecies" 3 Mystic)
  { cdSkills = [SkillWillpower]
  , cdCardTraits = setFromList [Item, Tome]
  , cdUses = Uses Secret 4
  }

keenEye :: CardDef
keenEye = (asset "07152" "Keen Eye" 2 Guardian)
  { cdCardTraits = setFromList [Talent]
  , cdSkills = [SkillIntellect, SkillCombat]
  }

physicalTraining2 :: CardDef
physicalTraining2 = (asset "50001" "Physical Training" 0 Guardian)
  { cdSkills = [SkillWillpower, SkillWillpower, SkillCombat, SkillCombat]
  , cdCardTraits = setFromList [Talent]
  , cdLevel = 2
  }

hyperawareness2 :: CardDef
hyperawareness2 = (asset "50003" "Hyperawareness" 0 Seeker)
  { cdSkills = [SkillIntellect, SkillIntellect, SkillAgility, SkillAgility]
  , cdCardTraits = setFromList [Talent]
  , cdLevel = 2
  }

hardKnocks2 :: CardDef
hardKnocks2 = (asset "50005" "Hard Knocks" 0 Rogue)
  { cdSkills = [SkillCombat, SkillCombat, SkillAgility, SkillAgility]
  , cdCardTraits = setFromList [Talent]
  , cdLevel = 2
  }

arcaneStudies2 :: CardDef
arcaneStudies2 = (asset "50007" "Arcane Studies" 0 Mystic)
  { cdSkills = [SkillWillpower, SkillWillpower, SkillIntellect, SkillIntellect]
  , cdCardTraits = setFromList [Talent]
  , cdLevel = 2
  }

digDeep2 :: CardDef
digDeep2 = (asset "50009" "Dig Deep" 0 Survivor)
  { cdSkills = [SkillWillpower, SkillWillpower, SkillAgility, SkillAgility]
  , cdCardTraits = setFromList [Talent]
  , cdLevel = 2
  }

rabbitsFoot3 :: CardDef
rabbitsFoot3 = (asset "50010" "Rabbit's Foot" 1 Survivor)
  { cdSkills = [SkillWild]
  , cdCardTraits = setFromList [Item, Charm]
  , cdLevel = 3
  }

arcaneEnlightenment :: CardDef
arcaneEnlightenment = (asset "60205" "Arcane Enlightenment" 2 Seeker)
  { cdSkills = [SkillWillpower, SkillWillpower]
  , cdCardTraits = setFromList [Ritual]
  }

celaenoFragments :: CardDef
celaenoFragments =
  (asset "60206" ("Celaeno Fragments" <:> "Book of Books") 1 Seeker)
    { cdSkills = [SkillIntellect]
    , cdCardTraits = setFromList [Item, Tome]
    , cdUnique = True
    }

encyclopedia :: CardDef
encyclopedia = (asset "60208" "Encyclopedia" 2 Seeker)
  { cdSkills = [SkillWild]
  , cdCardTraits = setFromList [Item, Tome]
  , cdUses = Uses Secret 5
  }

higherEducation :: CardDef
higherEducation = (asset "60211" "Higher Education" 0 Seeker)
  { cdSkills = [SkillWillpower, SkillIntellect]
  , cdCardTraits = setFromList [Talent]
  }

whittonGreene :: CardDef
whittonGreene =
  (asset "60213" ("Whitton Greene" <:> "Hunter of Rare Books") 4 Seeker)
    { cdSkills = [SkillIntellect]
    , cdCardTraits = setFromList [Ally, Miskatonic]
    , cdUnique = True
    }

ladyEsprit :: CardDef
ladyEsprit =
  (storyAsset "81019" ("Lady Esprit" <:> "Dangerous Bokor") 4 TheBayou)
    { cdSkills = [SkillWillpower, SkillIntellect, SkillWild]
    , cdCardTraits = setFromList [Ally, Sorcerer]
    , cdUnique = True
    }

bearTrap :: CardDef
bearTrap = (storyAsset "81020" "Bear Trap" 0 TheBayou)
  { cdCardTraits = setFromList [Trap]
  , cdCost = Nothing
  , cdCardType = EncounterAssetType
  }

fishingNet :: CardDef
fishingNet = (storyAsset "81021" "Fishing Net" 0 TheBayou)
  { cdCardTraits = setFromList [Trap]
  , cdCost = Nothing
  , cdCardType = EncounterAssetType
  }

monstrousTransformation :: CardDef
monstrousTransformation =
  fast $ (storyAsset "81030" "Monstrous Transformation" 0 CurseOfTheRougarou)
    { cdCardTraits = setFromList [Talent]
    }

maskedCarnevaleGoer_17 :: CardDef
maskedCarnevaleGoer_17 =
  (storyAsset "82017b" "Masked Carnevale-Goer" 0 CarnevaleOfHorrors)
    { cdCardTraits = singleton Carnevale
    }

maskedCarnevaleGoer_18 :: CardDef
maskedCarnevaleGoer_18 =
  (storyAsset "82018b" "Masked Carnevale-Goer" 0 CarnevaleOfHorrors)
    { cdCardTraits = singleton Carnevale
    }

maskedCarnevaleGoer_19 :: CardDef
maskedCarnevaleGoer_19 =
  (storyAsset "82019b" "Masked Carnevale-Goer" 0 CarnevaleOfHorrors)
    { cdCardTraits = singleton Carnevale
    }

maskedCarnevaleGoer_20 :: CardDef
maskedCarnevaleGoer_20 =
  (storyAsset "82020b" "Masked Carnevale-Goer" 0 CarnevaleOfHorrors)
    { cdCardTraits = singleton Carnevale
    }

innocentReveler :: CardDef
innocentReveler =
  (storyAssetWithMany "82021" "Innocent Reveler" 0 CarnevaleOfHorrors 3)
    { cdCardTraits = setFromList [Ally, Bystander, Carnevale]
    , cdCost = Nothing
    }

maskedCarnevaleGoer_21 :: CardDef
maskedCarnevaleGoer_21 =
  (storyAsset "82021b" "Masked Carnevale-Goer" 0 CarnevaleOfHorrors)
    { cdCardTraits = singleton Carnevale
    }

abbessAllegriaDiBiase :: CardDef
abbessAllegriaDiBiase = (storyAsset
                          "82022"
                          ("Abbess Allegria Di Biase" <:> "Most Blessed")
                          4
                          CarnevaleOfHorrors
                        )
  { cdCardTraits = setFromList [Ally, Believer]
  , cdUnique = True
  , cdSkills = [SkillWillpower, SkillIntellect, SkillWild]
  }

bauta :: CardDef
bauta = (storyAsset "82023" "Bauta" 1 CarnevaleOfHorrors)
  { cdCardTraits = setFromList [Item, Mask]
  , cdSkills = [SkillCombat, SkillWild]
  , cdLimits = [LimitPerTrait Mask 1]
  }

medicoDellaPeste :: CardDef
medicoDellaPeste =
  (storyAsset "82024" "Medico Della Peste" 1 CarnevaleOfHorrors)
    { cdCardTraits = setFromList [Item, Mask]
    , cdSkills = [SkillWillpower, SkillWild]
    , cdLimits = [LimitPerTrait Mask 1]
    }

pantalone :: CardDef
pantalone = (storyAsset "82025" "Pantalone" 1 CarnevaleOfHorrors)
  { cdCardTraits = setFromList [Item, Mask]
  , cdSkills = [SkillIntellect, SkillWild]
  , cdLimits = [LimitPerTrait Mask 1]
  }

gildedVolto :: CardDef
gildedVolto = (storyAsset "82026" "Gilded Volto" 1 CarnevaleOfHorrors)
  { cdCardTraits = setFromList [Item, Mask]
  , cdSkills = [SkillAgility, SkillWild]
  , cdLimits = [LimitPerTrait Mask 1]
  }

daisysToteBagAdvanced :: CardDef
daisysToteBagAdvanced = (asset "90002" "Daisy's Tote Bag" 2 Neutral)
  { cdSkills = [SkillWillpower, SkillIntellect, SkillWild, SkillWild]
  , cdCardTraits = setFromList [Item]
  , cdUnique = True
  }

theNecronomiconAdvanced :: CardDef
theNecronomiconAdvanced =
  (asset "90003" ("The Necronomicon" <:> "John Dee Translation") 0 Neutral)
    { cdCardTraits = setFromList [Item, Tome]
    , cdCardSubType = Just Weakness
    , cdRevelation = True
    , cdCost = Nothing
    }

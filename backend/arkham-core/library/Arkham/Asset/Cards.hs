module Arkham.Asset.Cards where

import Arkham.Prelude

import Arkham.Types.Card.CardCode
import Arkham.Types.Card.CardDef
import Arkham.Types.Card.CardType
import Arkham.Types.Card.Cost
import Arkham.Types.ClassSymbol
import Arkham.Types.EncounterSet hiding (Dunwich)
import qualified Arkham.Types.Keyword as Keyword
import Arkham.Types.Name
import Arkham.Types.SkillType
import Arkham.Types.Trait
import Arkham.Types.Window

storyAsset :: CardCode -> Name -> Int -> EncounterSet -> CardDef
storyAsset cardCode name cost encounterSet =
  baseAsset (Just (encounterSet, 1)) cardCode name cost Neutral

asset :: CardCode -> Name -> Int -> ClassSymbol -> CardDef
asset = baseAsset Nothing

permanent :: CardDef -> CardDef
permanent cd = cd { cdPermanent = True, cdCost = Nothing }

weakness :: CardCode -> Name -> CardDef
weakness cardCode name = (baseAsset Nothing cardCode name 0 Neutral)
  { cdWeakness = True
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
  , cdCost = Just (StaticCost cost)
  , cdLevel = 0
  , cdCardType = AssetType
  , cdWeakness = False
  , cdClassSymbol = Just classSymbol
  , cdSkills = mempty
  , cdCardTraits = mempty
  , cdKeywords = mempty
  , cdFast = False
  , cdWindows = mempty
  , cdFastWindow = Nothing
  , cdAction = Nothing
  , cdRevelation = False
  , cdVictoryPoints = Nothing
  , cdPlayRestrictions = mempty
  , cdCommitRestrictions = mempty
  , cdAttackOfOpportunityModifiers = mempty
  , cdPermanent = False
  , cdEncounterSet = fst <$> mEncounterSet
  , cdEncounterSetQuantity = snd <$> mEncounterSet
  , cdUnique = False
  , cdDoubleSided = False
  , cdLimits = []
  , cdExceptional = False
  }

allPlayerAssetCards :: HashMap CardCode CardDef
allPlayerAssetCards = mapFromList $ map
  (toCardCode &&& id)
  [ placeholderAsset
  , adaptable1
  , alyssaGraham
  , aquinnah1
  , arcaneEnlightenment
  , arcaneInitiate
  , arcaneStudies
  , arcaneStudies2
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
  , clarityOfMind
  , daisysToteBag
  , daisysToteBagAdvanced
  , darkHorse
  , digDeep
  , digDeep2
  , discOfItzamna2
  , drFrancisMorgan
  , drHenryArmitage
  , drMilanChristopher
  , duke
  , earlSawyer
  , elderSignAmulet3
  , encyclopedia
  , encyclopedia2
  , esotericFormula
  , fireAxe
  , fireExtinguisher1
  , firstAid
  , flashlight
  , forbiddenKnowledge
  , fortyFiveAutomatic
  , fortyOneDerringer
  , grotesqueStatue4
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
  , jennysTwin45s
  , jimsTrumpet
  , keenEye
  , keenEye3
  , knife
  , kukri
  , laboratoryAssistant
  , ladyEsprit
  , leatherCoat
  , leoDeLuca
  , leoDeLuca1
  , lightningGun5
  , liquidCourage
  , litaChantler
  , loneWolf
  , luckyDice2
  , machete
  , magnifyingGlass
  , magnifyingGlass1
  , medicalTexts
  , monstrousTransformation
  , newspaper
  , occultLexicon
  , oldBookOfLore
  , pathfinder1
  , peterSylvestre
  , peterSylvestre2
  , physicalTraining
  , physicalTraining2
  , pickpoketing
  , policeBadge2
  , powderOfIbnGhazi
  , professorWarrenRice
  , rabbitsFoot
  , rabbitsFoot3
  , relicHunter3
  , researchLibrarian
  , riteOfSeeking
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
  , streetwise3
  , painkillers
  , songOfTheDead2
  , springfieldM19034
  , strangeSolution
  , strayCat
  , switchblade
  , switchblade2
  , theNecronomicon
  , theNecronomiconAdvanced
  , theNecronomiconOlausWormiusTranslation
  , toothOfEztli
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
  ]

placeholderAsset :: CardDef
placeholderAsset = asset "asset" "Placeholder Asset" 0 Neutral

rolands38Special :: CardDef
rolands38Special = (asset "01006" "Roland's .38 Special" 3 Neutral)
  { cdSkills = [SkillCombat, SkillAgility, SkillWild]
  , cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdUnique = True
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
  }

magnifyingGlass :: CardDef
magnifyingGlass = (asset "01030" "Magnifying Glass" 1 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tool]
  , cdFast = True
  , cdWindows = setFromList [DuringTurn You]
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
magnifyingGlass1 = (asset "01040" "Magnifying Glass" 0 Seeker)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Item, Tool]
  , cdFast = True
  , cdWindows = setFromList [DuringTurn You]
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
switchblade = (asset "01044" "Switchblade" 1 Rogue)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Item, Weapon, Melee, Illicit]
  , cdFast = True
  , cdWindows = setFromList [DuringTurn You]
  }

burglary :: CardDef
burglary = (asset "01045" "Burglary" 1 Rogue)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Talent, Illicit]
  }

pickpoketing :: CardDef
pickpoketing = (asset "01046" "Pickpocketing" 2 Rogue)
  { cdSkills = [SkillAgility]
  , cdCardTraits = setFromList [Talent, Illicit]
  }

fortyOneDerringer :: CardDef
fortyOneDerringer = (asset "01047" ".41 Derringer" 3 Rogue)
  { cdSkills = [SkillCombat]
  , cdCardTraits = setFromList [Item, Weapon, Firearm, Illicit]
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
  }

scrying :: CardDef
scrying = (asset "01061" "Scrying" 1 Mystic)
  { cdSkills = [SkillIntellect]
  , cdCardTraits = setFromList [Spell]
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
  }

painkillers :: CardDef
painkillers = (asset "02117" "Painkillers" 1 Neutral)
  { cdCardTraits = singleton Item
  , cdSkills = [SkillWillpower]
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
switchblade2 = (asset "02152" "Switchblade" 1 Rogue)
  { cdSkills = [SkillCombat, SkillAgility]
  , cdCardTraits = setFromList [Item, Weapon, Melee, Illicit]
  , cdFast = True
  , cdWindows = setFromList [DuringTurn You]
  , cdLevel = 2
  }

shrivelling3 :: CardDef
shrivelling3 = (asset "02154" "Shrivelling" 3 Mystic)
  { cdSkills = [SkillWillpower, SkillCombat]
  , cdCardTraits = singleton Spell
  , cdLevel = 3
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

shrivelling5 :: CardDef
shrivelling5 = (asset "02306" "Shrivelling" 3 Mystic)
  { cdSkills = [SkillWillpower, SkillCombat, SkillCombat]
  , cdCardTraits = singleton Spell
  , cdLevel = 5
  }

keenEye :: CardDef
keenEye = (asset "07152" "Keen Eye" 2 Guardian)
  { cdCardTraits = setFromList [Talent]
  , cdSkills = [SkillIntellect, SkillCombat]
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

lightningGun5 :: CardDef
lightningGun5 = (asset "02301" "Lightning Gun" 6 Guardian)
  { cdCardTraits = setFromList [Item, Weapon, Firearm]
  , cdLevel = 5
  , cdSkills = [SkillIntellect, SkillCombat]
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
  }

fishingNet :: CardDef
fishingNet = (storyAsset "81021" "Fishing Net" 0 TheBayou)
  { cdCardTraits = setFromList [Trap]
  , cdCost = Nothing
  }

monstrousTransformation :: CardDef
monstrousTransformation =
  (storyAsset "81030" "Monstrous Transformation" 0 CurseOfTheRougarou)
    { cdCardTraits = setFromList [Talent]
    , cdFast = True
    , cdWindows = setFromList [DuringTurn You]
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
    , cdWeakness = True
    , cdRevelation = True
    , cdCost = Nothing
    }

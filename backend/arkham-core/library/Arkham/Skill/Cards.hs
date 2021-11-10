module Arkham.Skill.Cards where

import Arkham.Prelude

import Arkham.Types.Asset.Uses
import Arkham.Types.Card.CardCode
import Arkham.Types.Card.CardDef
import Arkham.Types.Card.CardType
import Arkham.Types.ClassSymbol
import Arkham.Types.CommitRestriction
import Arkham.Types.GameValue
import Arkham.Types.Matcher
import Arkham.Types.Name
import Arkham.Types.SkillType
import Arkham.Types.Trait

skill :: CardCode -> Name -> [SkillType] -> ClassSymbol -> CardDef
skill cardCode name skills classSymbol = CardDef
  { cdCardCode = cardCode
  , cdName = name
  , cdRevealedName = Nothing
  , cdCost = Nothing
  , cdLevel = 0
  , cdCardType = SkillType
  , cdCardSubType = Nothing
  , cdClassSymbol = Just classSymbol
  , cdSkills = skills
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
  , cdEncounterSet = Nothing
  , cdEncounterSetQuantity = Nothing
  , cdUnique = False
  , cdDoubleSided = False
  , cdLimits = []
  , cdExceptional = False
  , cdUses = NoUses
  , cdPlayableFromDiscard = False
  , cdStage = Nothing
  , cdSlots = []
  }

allPlayerSkillCards :: HashMap CardCode CardDef
allPlayerSkillCards = mapFromList $ map
  (toCardCode &&& id)
  [ deduction
  , deduction2
  , defiance
  , desperateSearch
  , doubleOrNothing
  , fearless
  , fearless2
  , guts
  , inquiringMind
  , leadership
  , manualDexterity
  , neitherRainNorSnow
  , opportunist
  , opportunist2
  , overpower
  , perception
  , quickThinking
  , recklessAssault
  , resourceful
  , riseToTheOccasion
  , runForYourLife
  , sayYourPrayers
  , strokeOfLuck2
  , survivalInstinct
  , survivalInstinct2
  , takeHeart
  , theHomeFront
  , trueUnderstanding
  , unexpectedCourage
  , unexpectedCourage2
  , viciousBlow
  , viciousBlow2
  ]

viciousBlow :: CardDef
viciousBlow = (skill "01025" "Vicious Blow" [SkillCombat] Guardian)
  { cdCardTraits = setFromList [Practiced]
  }

deduction :: CardDef
deduction = (skill "01039" "Deduction" [SkillIntellect] Seeker)
  { cdCardTraits = setFromList [Practiced]
  }

opportunist :: CardDef
opportunist = (skill "01053" "Opportunist" [SkillWild] Rogue)
  { cdCardTraits = setFromList [Innate]
  , cdCommitRestrictions = [OnlyYourTest]
  }

fearless :: CardDef
fearless = (skill "01067" "Fearless" [SkillWillpower] Mystic)
  { cdCardTraits = setFromList [Innate]
  }

survivalInstinct :: CardDef
survivalInstinct = (skill "01081" "Survival Instinct" [SkillAgility] Survivor)
  { cdCardTraits = setFromList [Innate]
  }

guts :: CardDef
guts = (skill "01089" "Guts" [SkillWillpower, SkillWillpower] Neutral)
  { cdCardTraits = setFromList [Innate]
  , cdCommitRestrictions = [MaxOnePerTest]
  }

perception :: CardDef
perception =
  (skill "01090" "Perception" [SkillIntellect, SkillIntellect] Neutral)
    { cdCardTraits = setFromList [Practiced]
    , cdCommitRestrictions = [MaxOnePerTest]
    }

overpower :: CardDef
overpower = (skill "01091" "Overpower" [SkillCombat, SkillCombat] Neutral)
  { cdCardTraits = setFromList [Practiced]
  , cdCommitRestrictions = [MaxOnePerTest]
  }

manualDexterity :: CardDef
manualDexterity =
  (skill "01092" "Manual Dexterity" [SkillAgility, SkillAgility] Neutral)
    { cdCardTraits = setFromList [Innate]
    , cdCommitRestrictions = [MaxOnePerTest]
    }

unexpectedCourage :: CardDef
unexpectedCourage =
  (skill "01093" "Unexpected Courage" [SkillWild, SkillWild] Neutral)
    { cdCardTraits = setFromList [Innate]
    , cdCommitRestrictions = [MaxOnePerTest]
    }

doubleOrNothing :: CardDef
doubleOrNothing = (skill "02026" "Double or Nothing" [SkillWild] Rogue)
  { cdCardTraits = singleton Fortune
  , cdCommitRestrictions = [MaxOnePerTest]
  }

deduction2 :: CardDef
deduction2 = (skill "02150" "Deduction" [SkillIntellect, SkillIntellect] Seeker
             )
  { cdCardTraits = setFromList [Practiced, Expert]
  , cdLevel = 2
  }

defiance :: CardDef
defiance = (skill "02190" "Defiance" [SkillWild] Mystic)
  { cdCardTraits = singleton Innate
  }

riseToTheOccasion :: CardDef
riseToTheOccasion = (skill
                      "02192"
                      "Rise to the Occasion"
                      [SkillWild, SkillWild, SkillWild]
                      Survivor
                    )
  { cdCardTraits = singleton Innate
  , cdCommitRestrictions = [OnlyYourTest, MinSkillTestValueDifference 2]
  }

inquiringMind :: CardDef
inquiringMind =
  (skill "02227" "Inquiring Mind" [SkillWild, SkillWild, SkillWild] Seeker)
    { cdCardTraits = singleton Innate
    , cdCommitRestrictions = [OnlyIfYourLocationHasClues]
    }

quickThinking :: CardDef
quickThinking = (skill "02229" "Quick Thinking" [SkillWild] Rogue)
  { cdCardTraits = singleton Innate
  }

opportunist2 :: CardDef
opportunist2 = (skill "02231" "Opportunist" [SkillWild] Rogue)
  { cdCardTraits = setFromList [Innate, Developed]
  , cdCommitRestrictions = [OnlyYourTest]
  , cdLevel = 2
  }

survivalInstinct2 :: CardDef
survivalInstinct2 =
  (skill "02235" "Survival Instinct" [SkillAgility, SkillAgility] Survivor)
    { cdCardTraits = setFromList [Innate, Developed]
    , cdLevel = 2
    }

leadership :: CardDef
leadership = (skill "02260" "Leadership" [SkillWild] Guardian)
  { cdCardTraits = singleton Practiced
  }

fearless2 :: CardDef
fearless2 = (skill "02268" "Fearless" [SkillWillpower, SkillWillpower] Mystic)
  { cdCardTraits = setFromList [Innate, Developed]
  , cdLevel = 2
  }

strokeOfLuck2 :: CardDef
strokeOfLuck2 = (skill "02271" "Stroke of Luck" [SkillWild] Survivor)
  { cdCardTraits = setFromList [Innate, Fortune]
  , cdLevel = 2
  , cdCommitRestrictions = [OnlyYourTest]
  }

viciousBlow2 :: CardDef
viciousBlow2 =
  (skill "02299" "Vicious Blow" [SkillCombat, SkillCombat] Guardian)
    { cdCardTraits = setFromList [Practiced, Expert]
    , cdLevel = 2
    }

theHomeFront :: CardDef
theHomeFront =
  (skill "03007" "The Home Front" (replicate 4 SkillCombat) Neutral)
    { cdCardTraits = setFromList [Practiced, Expert]
    }

sayYourPrayers :: CardDef
sayYourPrayers = (skill
                   "03116"
                   "Say Your Prayers"
                   [ SkillWillpower
                   , SkillWillpower
                   , SkillWillpower
                   , SkillWillpower
                   ]
                   Neutral
                 )
  { cdCardTraits = singleton Desperate
  , cdCommitRestrictions =
    [ MaxOnePerTest
    , SelfCanCommitWhen $ InvestigatorWithRemainingSanity $ AtMost $ Static 3
    ]
  }

desperateSearch :: CardDef
desperateSearch = (skill
                    "03117"
                    "Desperate Search"
                    [ SkillIntellect
                    , SkillIntellect
                    , SkillIntellect
                    , SkillIntellect
                    ]
                    Neutral
                  )
  { cdCardTraits = singleton Desperate
  , cdCommitRestrictions =
    [ MaxOnePerTest
    , SelfCanCommitWhen $ InvestigatorWithRemainingSanity $ AtMost $ Static 3
    ]
  }

recklessAssault :: CardDef
recklessAssault = (skill
                    "03118"
                    "Reckless Assault"
                    [SkillCombat, SkillCombat, SkillCombat, SkillCombat]
                    Neutral
                  )
  { cdCardTraits = singleton Desperate
  , cdCommitRestrictions =
    [ MaxOnePerTest
    , SelfCanCommitWhen $ InvestigatorWithRemainingSanity $ AtMost $ Static 3
    ]
  }

runForYourLife :: CardDef
runForYourLife = (skill
                   "03119"
                   "Run For Your Life"
                   [SkillAgility, SkillAgility, SkillAgility, SkillAgility]
                   Neutral
                 )
  { cdCardTraits = singleton Desperate
  , cdCommitRestrictions =
    [ MaxOnePerTest
    , SelfCanCommitWhen $ InvestigatorWithRemainingSanity $ AtMost $ Static 3
    ]
  }

resourceful :: CardDef
resourceful = (skill
                "03039"
                "Resourceful"
                [SkillIntellect, SkillCombat, SkillAgility]
                Survivor
              )
  { cdCardTraits = singleton Innate
  }

trueUnderstanding :: CardDef
trueUnderstanding = (skill "04153" "True Understanding" [SkillWild] Seeker)
  { cdCardTraits = setFromList [Innate]
  , cdCommitRestrictions = [ScenarioAbility]
  }

takeHeart :: CardDef
takeHeart = (skill "04201" "Take Heart" [] Survivor)
  { cdCardTraits = setFromList [Innate]
  , cdCommitRestrictions = [MaxOnePerTest]
  }

neitherRainNorSnow :: CardDef
neitherRainNorSnow = (skill
                       "60502"
                       "Neither Rain nor Snow"
                       [SkillWild, SkillWild, SkillWild]
                       Survivor
                     )
  { cdCardTraits = setFromList [Innate, Developed]
  }

unexpectedCourage2 :: CardDef
unexpectedCourage2 =
  (skill "60526" "Unexpected Courage" [SkillWild, SkillWild] Survivor)
    { cdCardTraits = setFromList [Innate, Developed]
    , cdCommitRestrictions = [MaxOnePerTest]
    , cdLevel = 2
    }

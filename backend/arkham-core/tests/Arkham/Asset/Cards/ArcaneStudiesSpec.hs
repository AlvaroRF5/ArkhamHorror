module Arkham.Asset.Cards.ArcaneStudiesSpec
  ( spec
  ) where

import TestImport

import Arkham.Ability
import Arkham.Asset.Cards qualified as Assets
import Arkham.Investigator.Types ( InvestigatorAttrs (..) )

spec :: Spec
spec = describe "Arcane Studies" $ do
  it "Adds 1 to willpower check for each resource spent" $ do
    investigator <- testJenny $ \attrs ->
      attrs { investigatorWillpower = 1, investigatorResources = 2 }
    arcaneStudies <- buildAsset Assets.arcaneStudies (Just investigator)

    (didPassTest, logger) <- didPassSkillTestBy investigator SkillWillpower 0

    gameTestWithLogger
        logger
        investigator
        [ SetTokens [Zero]
        , playAsset investigator arcaneStudies
        , beginSkillTest investigator SkillWillpower 3
        ]
        (entitiesL . assetsL %~ insertEntity arcaneStudies)
      $ do
          runMessages
          chooseOptionMatching
            "use ability"
            (\case
              AbilityLabel { ability } -> abilityIndex ability == 1
              _ -> False
            )
          chooseOptionMatching
            "use ability"
            (\case
              AbilityLabel { ability } -> abilityIndex ability == 1
              _ -> False
            )
          chooseOptionMatching
            "start skill test"
            (\case
              StartSkillTestButton{} -> True
              _ -> False
            )
          chooseOnlyOption "apply results"
          didPassTest `refShouldBe` True

  it "Adds 1 to intellect check for each resource spent" $ do
    investigator <- testJenny $ \attrs ->
      attrs { investigatorIntellect = 1, investigatorResources = 2 }
    arcaneStudies <- buildAsset Assets.arcaneStudies (Just investigator)

    (didPassTest, logger) <- didPassSkillTestBy investigator SkillIntellect 0

    gameTestWithLogger
        logger
        investigator
        [ SetTokens [Zero]
        , playAsset investigator arcaneStudies
        , beginSkillTest investigator SkillIntellect 3
        ]
        (entitiesL . assetsL %~ insertEntity arcaneStudies)
      $ do
          runMessages
          chooseOptionMatching
            "use ability"
            (\case
              AbilityLabel { ability } -> abilityIndex ability == 2
              _ -> False
            )
          chooseOptionMatching
            "use ability"
            (\case
              AbilityLabel { ability } -> abilityIndex ability == 2
              _ -> False
            )
          chooseOptionMatching
            "start skill test"
            (\case
              StartSkillTestButton{} -> True
              _ -> False
            )
          chooseOnlyOption "apply results"
          didPassTest `refShouldBe` True

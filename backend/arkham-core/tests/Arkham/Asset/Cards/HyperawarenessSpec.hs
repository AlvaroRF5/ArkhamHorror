module Arkham.Asset.Cards.HyperawarenessSpec
  ( spec
  ) where

import TestImport

import Arkham.Ability
import Arkham.Asset.Cards qualified as Assets
import Arkham.Investigator.Types ( InvestigatorAttrs (..) )

spec :: Spec
spec = describe "Hyperawareness" $ do
  it "Adds 1 to intellect check for each resource spent" $ do
    investigator <- testJenny $ \attrs ->
      attrs { investigatorIntellect = 1, investigatorResources = 2 }
    hyperawareness <- buildAsset Assets.hyperawareness (Just investigator)

    (didPassTest, logger) <- didPassSkillTestBy investigator SkillIntellect 0

    gameTestWithLogger
        logger
        investigator
        [ SetTokens [Zero]
        , playAsset investigator hyperawareness
        , beginSkillTest investigator SkillIntellect 3
        ]
        (entitiesL . assetsL %~ insertEntity hyperawareness)
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

  it "Adds 1 to agility check for each resource spent" $ do
    investigator <- testJenny
      $ \attrs -> attrs { investigatorAgility = 1, investigatorResources = 2 }
    hyperawareness <- buildAsset Assets.hyperawareness (Just investigator)

    (didPassTest, logger) <- didPassSkillTestBy investigator SkillAgility 0

    gameTestWithLogger
        logger
        investigator
        [ SetTokens [Zero]
        , playAsset investigator hyperawareness
        , beginSkillTest investigator SkillAgility 3
        ]
        (entitiesL . assetsL %~ insertEntity hyperawareness)
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

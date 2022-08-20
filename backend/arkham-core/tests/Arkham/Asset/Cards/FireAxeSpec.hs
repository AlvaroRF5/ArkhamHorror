module Arkham.Asset.Cards.FireAxeSpec
  ( spec
  ) where

import TestImport hiding (EnemyDamage)

import Arkham.Asset.Types ( Field (..) )
import Arkham.Asset.Cards qualified as Assets
import Arkham.Enemy.Types ( Field (..), EnemyAttrs (..) )
import Arkham.Investigator.Types ( InvestigatorAttrs (..) )
import Arkham.Projection

spec :: Spec
spec = describe "Fire Axe" $ do
  it "gives +1 damage if you have no resources" $ do
    investigator <- testJenny
      $ \attrs -> attrs { investigatorResources = 0, investigatorCombat = 3 }
    fireAxe <- buildAsset Assets.fireAxe (Just investigator)
    enemy <- testEnemy
      $ \attrs -> attrs { enemyHealth = Static 3, enemyFight = 3 }
    location <- testLocation id
    gameTest
        investigator
        [ SetTokens [Zero]
        , playAsset investigator fireAxe
        , enemySpawn location enemy
        , moveTo investigator location
        ]
        ((entitiesL . enemiesL %~ insertEntity enemy)
        . (entitiesL . assetsL %~ insertEntity fireAxe)
        . (entitiesL . locationsL %~ insertEntity location)
        )
      $ do
          runMessages
          [doFight, _] <- field AssetAbilities (toId fireAxe)
          push $ UseAbility (toId investigator) doFight []
          runMessages
          chooseOnlyOption "Fight enemy"
          chooseOnlyOption "Start skill test"
          chooseOnlyOption "Apply Results"
          fieldAssert EnemyDamage (== 2) enemy

  it "allows you to spend 1 resource to get +2 combat" $ do
    investigator <- testJenny
      $ \attrs -> attrs { investigatorResources = 2, investigatorCombat = 1 }
    fireAxe <- buildAsset Assets.fireAxe (Just investigator)
    enemy <- testEnemy
      $ \attrs -> attrs { enemyHealth = Static 3, enemyFight = 3 }
    location <- testLocation id
    gameTest
        investigator
        [ SetTokens [Zero]
        , playAsset investigator fireAxe
        , enemySpawn location enemy
        , moveTo investigator location
        ]
        ((entitiesL . enemiesL %~ insertEntity enemy)
        . (entitiesL . assetsL %~ insertEntity fireAxe)
        . (entitiesL . locationsL %~ insertEntity location)
        )
      $ do
          runMessages
          [doFight, _] <- field AssetAbilities (toId fireAxe)
          push $ UseAbility (toId investigator) doFight []
          runMessages
          chooseOnlyOption "Fight enemy"
          chooseOptionMatching
            "spend resource"
            (\case
              AbilityLabel{} -> True
              _ -> False
            )
          chooseOptionMatching
            "Skip playing fast cards or using reactions and continue"
            (\case
              Label{} -> True
              _ -> False
            )
          chooseOptionMatching
            "Start Skill Test"
            (\case
              StartSkillTestButton{} -> True
              _ -> False
            )
          chooseOptionMatching
            "Skip playing fast cards or using reactions and continue"
            (\case
              Label{} -> True
              _ -> False
            )
          chooseOnlyOption "Apply Results"
          fieldAssert EnemyDamage (== 1) enemy

  it "if you spend your resources before tokens, you stil get +1 damage" $ do
    investigator <- testJenny
      $ \attrs -> attrs { investigatorResources = 1, investigatorCombat = 1 }
    fireAxe <- buildAsset Assets.fireAxe (Just investigator)
    enemy <- testEnemy
      $ \attrs -> attrs { enemyHealth = Static 3, enemyFight = 3 }
    location <- testLocation id
    gameTest
        investigator
        [ SetTokens [Zero]
        , playAsset investigator fireAxe
        , enemySpawn location enemy
        , moveTo investigator location
        ]
        ((entitiesL . enemiesL %~ insertEntity enemy)
        . (entitiesL . assetsL %~ insertEntity fireAxe)
        . (entitiesL . locationsL %~ insertEntity location)
        )
      $ do
          runMessages
          [doFight, _] <- field AssetAbilities (toId fireAxe)
          push $ UseAbility (toId investigator) doFight []
          runMessages
          chooseOnlyOption "Fight enemy"
          chooseOptionMatching
            "spend resource"
            (\case
              AbilityLabel{} -> True
              _ -> False
            )
          chooseOptionMatching
            "Start Skill Test"
            (\case
              StartSkillTestButton{} -> True
              _ -> False
            )
          chooseOnlyOption "Apply Results"
          fieldAssert EnemyDamage (== 2) enemy

  it "limit of 3 resources can be spent" $ do
    investigator <- testJenny
      $ \attrs -> attrs { investigatorResources = 4, investigatorCombat = 1 }
    fireAxe <- buildAsset Assets.fireAxe (Just investigator)
    enemy <- testEnemy
      $ \attrs -> attrs { enemyHealth = Static 3, enemyFight = 3 }
    location <- testLocation id
    gameTest
        investigator
        [ SetTokens [Zero]
        , playAsset investigator fireAxe
        , enemySpawn location enemy
        , moveTo investigator location
        ]
        ((entitiesL . enemiesL %~ insertEntity enemy)
        . (entitiesL . assetsL %~ insertEntity fireAxe)
        . (entitiesL . locationsL %~ insertEntity location)
        )
      $ do
          runMessages
          [doFight, _] <- field AssetAbilities (toId fireAxe)
          push $ UseAbility (toId investigator) doFight []
          runMessages
          chooseOnlyOption "Fight enemy"
          chooseOptionMatching
            "spend resource"
            (\case
              AbilityLabel{} -> True
              _ -> False
            )
          chooseOptionMatching
            "spend resource"
            (\case
              AbilityLabel{} -> True
              _ -> False
            )
          chooseOptionMatching
            "spend resource"
            (\case
              AbilityLabel{} -> True
              _ -> False
            )
          chooseOnlyOption "Start skill test"
          chooseOnlyOption "Apply Results"
          fieldAssert EnemyDamage (== 1) enemy

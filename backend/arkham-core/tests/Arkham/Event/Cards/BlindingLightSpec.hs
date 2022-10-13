{-# OPTIONS_GHC -Wno-incomplete-uni-patterns #-}
module Arkham.Event.Cards.BlindingLightSpec
  ( spec
  ) where

import TestImport.Lifted hiding (EnemyDamage)

import Arkham.Enemy.Types qualified as EnemyAttrs
import Arkham.Event.Cards qualified as Events
import Arkham.Investigator.Types (InvestigatorAttrs(..), willpowerL)
import Arkham.Enemy.Types (Field(..))

spec :: Spec
spec = do
  describe "Blinding Light" $ do
    it "Uses willpower to evade an enemy" $ do
      investigator <- testJenny $ \attrs ->
        attrs { investigatorWillpower = 5, investigatorAgility = 3 }
      enemy <- testEnemy
        ((EnemyAttrs.evadeL ?~ 4) . (EnemyAttrs.healthL .~ Static 2))
      blindingLight <- buildEvent Events.blindingLight investigator
      location <- testLocation id
      gameTest
          investigator
          [ SetTokens [MinusOne]
          , enemySpawn location enemy
          , moveTo investigator location
          , playEvent investigator blindingLight
          ]
          ((entitiesL . eventsL %~ insertEntity blindingLight)
          . (entitiesL . enemiesL %~ insertEntity enemy)
          . (entitiesL . locationsL %~ insertEntity location)
          )
        $ do
            runMessages
            chooseOnlyOption "Evade enemy"
            chooseOnlyOption "Run skill check"
            chooseOnlyOption "Apply results"

            isInDiscardOf investigator blindingLight `shouldReturn` True
            evadedBy investigator enemy `shouldReturn` True

    it "deals 1 damage to the evaded enemy" $ do
      investigator <- testJenny (willpowerL .~ 5)
      enemy <- testEnemy
        ((EnemyAttrs.evadeL ?~ 4) . (EnemyAttrs.healthL .~ Static 2))
      blindingLight <- buildEvent Events.blindingLight investigator
      location <- testLocation id
      gameTest
          investigator
          [ SetTokens [MinusOne]
          , enemySpawn location enemy
          , moveTo investigator location
          , playEvent investigator blindingLight
          ]
          ((entitiesL . eventsL %~ insertEntity blindingLight)
          . (entitiesL . enemiesL %~ insertEntity enemy)
          . (entitiesL . locationsL %~ insertEntity location)
          )
        $ do
            runMessages
            chooseOnlyOption "Evade enemy"
            chooseOnlyOption "Run skill check"
            chooseOnlyOption "Apply results"

            isInDiscardOf investigator blindingLight `shouldReturn` True
            fieldAssert EnemyDamage (== 1) enemy

    it
        "On Skull, Cultist, Tablet, ElderThing, or AutoFail the investigator loses an action"
      $ for_ [Skull, Cultist, Tablet, ElderThing, AutoFail]
      $ \token -> do
          investigator <- testJenny (willpowerL .~ 5)
          enemy <- testEnemy
            ((EnemyAttrs.evadeL ?~ 4) . (EnemyAttrs.healthL .~ Static 2))
          blindingLight <- buildEvent Events.blindingLight investigator
          location <- testLocation id
          gameTest
              investigator
              [ SetTokens [token]
              , enemySpawn location enemy
              , moveTo investigator location
              , playEvent investigator blindingLight
              ]
              ((entitiesL . eventsL %~ insertEntity blindingLight)
              . (entitiesL . enemiesL %~ insertEntity enemy)
              . (entitiesL . locationsL %~ insertEntity location)
              )
            $ do
                runMessages
                chooseOnlyOption "Evade enemy"
                chooseOnlyOption "Run skill check"
                chooseOnlyOption "Apply results"

                isInDiscardOf investigator blindingLight `shouldReturn` True
                getRemainingActions investigator `shouldReturn` 2

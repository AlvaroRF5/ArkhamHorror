module Arkham.Types.Treachery.Cards.SmiteTheWickedSpec
  ( spec
  ) where

import TestImport.Lifted

import qualified Arkham.Enemy.Cards as Cards
import qualified Arkham.Treachery.Cards as Cards

spec :: Spec
spec = describe "Smite the Wicked" $ do
  it "draws an enemy, attaches to it, and spawns farthest away from you" $ do
    investigator <- testInvestigator "00000" id
    smiteTheWicked <- genPlayerCard Cards.smiteTheWicked
    enemy <- genEncounterCard Cards.swarmOfRats
    treachery <- genEncounterCard Cards.ancientEvils
    (location1, location2) <- testConnectedLocations id id
    gameTest
        investigator
        [ placedLocation location1
        , placedLocation location2
        , SetEncounterDeck (Deck [treachery, enemy])
        , loadDeck investigator [smiteTheWicked]
        , moveTo investigator location1
        , drawCards investigator 1
        ]
        ((locationsL %~ insertEntity location1)
        . (locationsL %~ insertEntity location2)
        )
      $ do
          runMessages
          chooseOnlyOption "place enemy"
          game <- getTestGame
          let enemy' = game ^?! enemiesL . to toList . ix 0
          location2' <- updated location2
          hasEnemy enemy' location2' `shouldReturn` True
          hasTreacheryWithMatchingCardCode (PlayerCard smiteTheWicked) enemy'
            `shouldReturn` True

  it "causes 1 mental trauma if enemy not defeated" $ do
    investigator <- testInvestigator "00000" id
    smiteTheWicked <- genPlayerCard Cards.smiteTheWicked
    enemy <- genEncounterCard Cards.swarmOfRats
    location <- testLocation id
    gameTest
        investigator
        [ SetEncounterDeck (Deck [enemy])
        , loadDeck investigator [smiteTheWicked]
        , moveTo investigator location
        , drawCards investigator 1
        , EndOfGame
        ]
        (locationsL %~ insertEntity location)
      $ do
          runMessages
          chooseOnlyOption "place enemy"
          updated investigator `shouldSatisfyM` hasTrauma (0, 1)

  it "won't cause trauma if enemy is defeated" $ do
    investigator <- testInvestigator "00000" id
    smiteTheWicked <- genPlayerCard Cards.smiteTheWicked
    enemy <- genEncounterCard Cards.swarmOfRats
    location <- testLocation id
    gameTest
        investigator
        [ placedLocation location
        , SetEncounterDeck (Deck [enemy])
        , loadDeck investigator [smiteTheWicked]
        , moveTo investigator location
        , drawCards investigator 1
        ]
        (locationsL %~ insertEntity location)
      $ do
          runMessages
          chooseOnlyOption "place enemy"
          game <- getTestGame
          let updatedEnemy = game ^?! enemiesL . to toList . ix 0
          pushAll
            [ EnemyDefeated
              (toId updatedEnemy)
              (toId investigator)
              (toId location)
              (toCardCode enemy)
              (toSource investigator)
              []
            , EndOfGame
            ]
          runMessages

          updated investigator `shouldSatisfyM` hasTrauma (0, 0)
          isInDiscardOf investigator smiteTheWicked `shouldReturn` True

  it "will cause trauma if player is eliminated" $ do
    investigator <- testInvestigator "00000" id
    smiteTheWicked <- genPlayerCard Cards.smiteTheWicked
    enemy <- genEncounterCard Cards.swarmOfRats
    location <- testLocation id
    gameTest
        investigator
        [ placedLocation location
        , SetEncounterDeck (Deck [enemy])
        , loadDeck investigator [smiteTheWicked]
        , moveTo investigator location
        , drawCards investigator 1
        , Resign (toId investigator)
        ]
        (locationsL %~ insertEntity location)
      $ do
          runMessages
          chooseOnlyOption "place enemy"
          updated investigator `shouldSatisfyM` hasTrauma (0, 1)

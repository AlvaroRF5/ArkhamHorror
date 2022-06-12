module Arkham.Event.Cards.BarricadeSpec
  ( spec
  ) where

import TestImport.Lifted

import Arkham.Modifier
import Arkham.Investigator.Attrs (Field(..))
import Arkham.Location.Attrs (Field(..))
import Arkham.Projection

spec :: Spec
spec = do
  describe "Barricade" $ do
    it "should make the current location unenterable by non elites" $ do
      location <- testLocation id
      investigator <- testInvestigator id
      barricade <- buildEvent "01038" investigator
      gameTest
          investigator
          [moveTo investigator location, playEvent investigator barricade]
          ((entitiesL . eventsL %~ insertEntity barricade)
          . (entitiesL . locationsL %~ insertEntity location)
          )
        $ do
            runMessages
            getModifiers (TestSource mempty) (toTarget location)
              `shouldReturn` [CannotBeEnteredByNonElite]
            assert $ fieldP LocationEvents (== setFromList [toId barricade]) (toId location)
            assert $ fieldP InvestigatorDiscard null (toId investigator)

    it "should be discarded if an investigator leaves the location" $ do
      (location1, location2) <- testConnectedLocations id id
      investigator <- testInvestigator id
      investigator2 <- testInvestigator id
      barricade <- buildEvent "01038" investigator
      let Just barricadeCard = preview _PlayerCard (toCard $ toAttrs barricade)
      gameTest
          investigator
          [ moveAllTo location1
          , playEvent investigator barricade
          , Move (toSource investigator2) (toId investigator2) (toId location1) (toId location2)
          ]
          ((entitiesL . eventsL %~ insertEntity barricade)
          . (entitiesL . locationsL %~ insertEntity location1)
          . (entitiesL . locationsL %~ insertEntity location2)
          . (entitiesL . investigatorsL %~ insertEntity investigator2)
          )
        $ do
            runMessages
            chooseOnlyOption "trigger barricade"
            getModifiers (TestSource mempty) (toTarget location1)
              `shouldReturn` []
            assert $ fieldP LocationEvents null (toId location1)
            assert $ fieldP InvestigatorDiscard (== [barricadeCard]) (toId investigator)

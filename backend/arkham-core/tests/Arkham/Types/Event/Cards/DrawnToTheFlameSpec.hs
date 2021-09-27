module Arkham.Types.Event.Cards.DrawnToTheFlameSpec
  ( spec
  ) where

import TestImport.Lifted

import Arkham.Location.Cards qualified as Cards
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Types.Investigator.Attrs (InvestigatorAttrs(..))

spec :: Spec
spec = describe "Drawn to the flame" $ do
  it "draws the top card of the encounter deck and then you discover two clues"
    $ do
    -- We use "On Wings of Darkness" here to check that the Revelation effect
    -- resolves and that the clues discovered are at your location after the
    -- effect per the FAQ
        investigator <- testInvestigator "00000"
          $ \attrs -> attrs { investigatorAgility = 3 }
        rivertown <- createLocation <$> genEncounterCard Cards.rivertown
        southside <- createLocation
          <$> genEncounterCard Cards.southsideHistoricalSociety
        drawnToTheFlame <- buildEvent "01064" investigator
        onWingsOfDarkness <- genEncounterCard Cards.onWingsOfDarkness
        gameTest
            investigator
            [ SetEncounterDeck (Deck [onWingsOfDarkness])
            , SetTokens [Zero]
            , placedLocation rivertown
            , placedLocation southside
            , PlaceClues (toTarget rivertown) 1
            , moveTo investigator southside
            , playEvent investigator drawnToTheFlame
            ]
            ((eventsL %~ insertEntity drawnToTheFlame)
            . (locationsL %~ insertEntity rivertown)
            . (locationsL %~ insertEntity southside)
            )
          $ do
              runMessages
              chooseOnlyOption "start skill test"
              chooseOnlyOption "apply results"
              chooseFirstOption "apply horror/damage"
              chooseFirstOption "apply horror/damage"
              chooseOnlyOption "move to central location"
              updated investigator `shouldSatisfyM` hasClueCount 2
              isInDiscardOf investigator drawnToTheFlame `shouldReturn` True

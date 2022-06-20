module Arkham.Location.Cards.TheHiddenChamber
  ( theHiddenChamber
  , TheHiddenChamber(..)
  ) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Assets
import Arkham.Location.Cards qualified as Cards
import Arkham.Card
import Arkham.Classes
import Arkham.GameValue
import Arkham.Helpers.Investigator
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher hiding (RevealLocation)
import Arkham.Message
import Arkham.Name
import Arkham.Projection

newtype TheHiddenChamber = TheHiddenChamber LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

theHiddenChamber :: LocationCard TheHiddenChamber
theHiddenChamber =
  location TheHiddenChamber Cards.theHiddenChamber 3 (Static 0) NoSymbol []

instance HasModifiersFor TheHiddenChamber where
  getModifiersFor _ target (TheHiddenChamber attrs) | isTarget attrs target = do
    mKeyToTheChamber <- selectOne (assetIs Assets.keyToTheChamber)
    pure $ toModifiers
      attrs
      (case mKeyToTheChamber of
        Just keyToTheChamber | keyToTheChamber `member` locationAssets attrs ->
          []
        _ -> [Blocked]
      )
  getModifiersFor _ _ _ = pure []

instance RunMessage TheHiddenChamber where
  runMessage msg (TheHiddenChamber attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      connectedLocation <- getJustLocation iid
      name <- field LocationName connectedLocation
      pushAll
        [ PlaceLocation (toCard attrs)
        , AddDirectConnection (toId attrs) connectedLocation
        , AddDirectConnection connectedLocation (toId attrs)
        , SetLocationLabel (toId attrs) $ nameToLabel name <> "HiddenChamber"
        ]
      TheHiddenChamber <$> runMessage msg attrs
    -- Revealing will cause the other location to drop it's known connections
    -- So we must queue up to add it back
    _ -> TheHiddenChamber <$> runMessage msg attrs

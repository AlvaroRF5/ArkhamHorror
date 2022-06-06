module Arkham.Act.Cards.MistakesOfThePast
  ( MistakesOfThePast(..)
  , mistakesOfThePast
  ) where

import Arkham.Prelude

import Arkham.Act.Attrs
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Helpers
import Arkham.Act.Runner
import Arkham.Asset.Cards qualified as Assets
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype MistakesOfThePast = MistakesOfThePast ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

mistakesOfThePast :: ActCard MistakesOfThePast
mistakesOfThePast = act
  (2, A)
  MistakesOfThePast
  Cards.mistakesOfThePast
  (Just $ GroupClueCost (PerPlayer 2) Anywhere)

instance ActRunner env => RunMessage MistakesOfThePast where
  runMessage msg a@(MistakesOfThePast attrs) = case msg of
    AdvanceAct aid _ _ | aid == toId a && onSide B attrs -> do
      locations <- selectList $ RevealedLocation <> LocationWithTitle
        "Historical Society"
      hiddenLibrary <- getSetAsideCard Locations.hiddenLibrary
      mrPeabody <- getSetAsideCard Assets.mrPeabody
      leadInvestigatorId <- getLeadInvestigatorId
      investigatorIds <- getInvestigatorIds
      playerCount <- getPlayerCount
      a <$ pushAll
        ([ PlaceCluesUpToClueValue location playerCount
         | location <- locations
         ]
        <> [ chooseOne
             leadInvestigatorId
             [ TargetLabel
                 (InvestigatorTarget iid)
                 [TakeControlOfSetAsideAsset iid mrPeabody]
             | iid <- investigatorIds
             ]
           , PlaceLocation hiddenLibrary
           , AdvanceActDeck (actDeckId attrs) (toSource attrs)
           ]
        )
    _ -> MistakesOfThePast <$> runMessage msg attrs

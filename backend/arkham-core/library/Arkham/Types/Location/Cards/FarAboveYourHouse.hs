module Arkham.Types.Location.Cards.FarAboveYourHouse where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (farAboveYourHouse)
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype FarAboveYourHouse = FarAboveYourHouse LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

farAboveYourHouse :: LocationCard FarAboveYourHouse
farAboveYourHouse = location
  FarAboveYourHouse
  Cards.farAboveYourHouse
  2
  (PerPlayer 1)
  Moon
  [Triangle]

instance HasModifiersFor env FarAboveYourHouse where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env FarAboveYourHouse where
  getActions i window (FarAboveYourHouse attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env FarAboveYourHouse where
  runMessage msg l@(FarAboveYourHouse attrs) = case msg of
    RevealLocation (Just iid) lid | lid == locationId attrs -> do
      push
        (BeginSkillTest
          iid
          (toSource attrs)
          (InvestigatorTarget iid)
          Nothing
          SkillWillpower
          4
        )
      FarAboveYourHouse <$> runMessage msg attrs
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source -> do
        investigatorIds <- getInvestigatorIds
        l <$ pushAll
          (concat $ replicate @[[Message]]
            n
            [ RandomDiscard iid' | iid' <- investigatorIds ]
          )
    _ -> FarAboveYourHouse <$> runMessage msg attrs

{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Location.Cards.FarAboveYourHouse where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Game.Helpers
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner

newtype FarAboveYourHouse = FarAboveYourHouse Attrs
  deriving newtype (Show, ToJSON, FromJSON)

farAboveYourHouse :: FarAboveYourHouse
farAboveYourHouse = FarAboveYourHouse $ base { locationVictory = Just 1 }
 where
  base = baseAttrs
    "50019"
    (LocationName "Field of Graves" Nothing)
    EncounterSet.ReturnToTheGathering
    2
    (PerPlayer 1)
    Moon
    [Triangle]
    mempty

instance HasModifiersFor env FarAboveYourHouse where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env FarAboveYourHouse where
  getActions i window (FarAboveYourHouse attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env FarAboveYourHouse where
  runMessage msg l@(FarAboveYourHouse attrs) = case msg of
    RevealLocation (Just iid) lid | lid == locationId attrs -> do
      unshiftMessage
        (BeginSkillTest
          iid
          (toSource attrs)
          (InvestigatorTarget iid)
          Nothing
          SkillWillpower
          4
        )
      FarAboveYourHouse <$> runMessage msg attrs
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} n
      | isSource attrs source -> do
        investigatorIds <- getInvestigatorIds
        l <$ unshiftMessages
          (concat $ replicate @[[Message]]
            n
            [ RandomDiscard iid' | iid' <- investigatorIds ]
          )
    _ -> FarAboveYourHouse <$> runMessage msg attrs

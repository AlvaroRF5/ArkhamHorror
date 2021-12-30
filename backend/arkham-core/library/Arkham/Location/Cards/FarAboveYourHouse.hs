module Arkham.Location.Cards.FarAboveYourHouse where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (farAboveYourHouse)
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Location.Attrs
import Arkham.Matcher
import Arkham.Message hiding (RevealLocation)
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype FarAboveYourHouse = FarAboveYourHouse LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

farAboveYourHouse :: LocationCard FarAboveYourHouse
farAboveYourHouse = location
  FarAboveYourHouse
  Cards.farAboveYourHouse
  2
  (PerPlayer 1)
  Moon
  [Triangle]

instance HasAbilities FarAboveYourHouse where
  getAbilities (FarAboveYourHouse attrs) =
    withBaseAbilities attrs $
      [ mkAbility attrs 1
        $ ForcedAbility
        $ RevealLocation Timing.After You
        $ LocationWithId
        $ toId attrs
      | locationRevealed attrs
      ]

instance (LocationRunner env) => RunMessage env FarAboveYourHouse where
  runMessage msg l@(FarAboveYourHouse attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> l <$ push
      (BeginSkillTest
        iid
        (toSource attrs)
        (InvestigatorTarget iid)
        Nothing
        SkillWillpower
        4
      )
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source -> do
        investigatorIds <- getInvestigatorIds
        l <$ pushAll
          (concat $ replicate @[[Message]]
            n
            [ RandomDiscard iid' | iid' <- investigatorIds ]
          )
    _ -> FarAboveYourHouse <$> runMessage msg attrs

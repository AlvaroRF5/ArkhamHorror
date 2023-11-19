module Arkham.Act.Cards.TheFinalDescent (
  TheFinalDescent (..),
  theFinalDescent,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.ChaosToken
import Arkham.Classes
import Arkham.Matcher
import Arkham.Trait (Trait (Steps))

newtype TheFinalDescent = TheFinalDescent ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theFinalDescent :: ActCard TheFinalDescent
theFinalDescent = act (3, A) TheFinalDescent Cards.theFinalDescent Nothing

instance HasAbilities TheFinalDescent where
  getAbilities (TheFinalDescent x) =
    [ restrictedAbility x 1 (EachUndefeatedInvestigator $ InvestigatorAt "The Enchanted Path")
        $ Objective
        $ ForcedAbility AnyWindow
    ]

instance RunMessage TheFinalDescent where
  runMessage msg a@(TheFinalDescent attrs) = case msg of
    UseThisAbility _ (isSource attrs -> True) 1 -> do
      push $ advancedWithOther attrs
      pure a
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs -> do
      investigators <- getInvestigators
      steps <- selectList $ LocationWithTrait Steps
      placeEnchantedWoods <-
        traverse placeLocation_ . take 6 =<< shuffleM =<< getSetAsideCardsMatching "The Enchanted Woods"
      pushAll
        $ map (RemoveAllClues (toSource attrs) . toTarget) investigators
        <> [AddChaosToken Skull]
        <> [RemoveLocation step | step <- steps]
        <> placeEnchantedWoods
        <> [ advanceActDeck attrs
           ]
      pure a
    _ -> TheFinalDescent <$> runMessage msg attrs

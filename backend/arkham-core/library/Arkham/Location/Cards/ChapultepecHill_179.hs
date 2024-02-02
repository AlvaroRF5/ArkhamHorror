module Arkham.Location.Cards.ChapultepecHill_179 (
  chapultepecHill_179,
  ChapultepecHill_179 (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.GameValue
import Arkham.Helpers.Modifiers
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Trait

newtype ChapultepecHill_179 = ChapultepecHill_179 LocationAttrs
  deriving anyclass (IsLocation)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks, NFData)

chapultepecHill_179 :: LocationCard ChapultepecHill_179
chapultepecHill_179 =
  locationWith ChapultepecHill_179 Cards.chapultepecHill_179 4 (PerPlayer 1) (labelL .~ "triangle")

instance HasModifiersFor ChapultepecHill_179 where
  getModifiersFor (InvestigatorTarget iid) (ChapultepecHill_179 a) = do
    here <- iid `isAt` a
    pure $ toModifiers a [SkillModifier #willpower (-2) | here]
  getModifiersFor _ _ = pure []

instance HasAbilities ChapultepecHill_179 where
  getAbilities (ChapultepecHill_179 attrs) =
    withRevealedAbilities
      attrs
      [ limitedAbility (GroupLimit PerPhase 1)
          $ restrictedAbility
            attrs
            1
            (Here <> CluesOnThis (atLeast 1) <> CanDiscoverCluesAt (LocationWithId $ toId attrs))
          $ freeReaction
          $ DrawCard #after You (BasicCardMatch $ CardWithTrait Hex) AnyDeck
      ]

instance RunMessage ChapultepecHill_179 where
  runMessage msg l@(ChapultepecHill_179 attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $ InvestigatorDiscoverClues iid (toId attrs) (toAbilitySource attrs 1) 1 Nothing
      pure l
    _ -> ChapultepecHill_179 <$> runMessage msg attrs

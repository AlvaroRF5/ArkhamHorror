module Arkham.Location.Cards.TrophyRoom
  ( trophyRoom
  , TrophyRoom(..)
  )
where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Game.Helpers
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message

newtype TrophyRoom = TrophyRoom LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

trophyRoom :: LocationCard TrophyRoom
trophyRoom = location TrophyRoom Cards.trophyRoom 2 (Static 0)

instance HasAbilities TrophyRoom where
  getAbilities (TrophyRoom a) = withBaseAbilities a
    [ restrictedAbility a 1
        (Here <> InvestigatorExists
          (You <> AnyInvestigator [InvestigatorCanGainResources, investigatorWithSpendableResources 2])
        )
      $ ActionAbility Nothing
      $ ActionCost 1
    ]

instance RunMessage TrophyRoom where
  runMessage msg l@(TrophyRoom attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      canGainResources <- iid <=~> InvestigatorCanGainResources
      hasTwoResources <- (> 2) <$> getSpendableResources iid
      push $ chooseOrRunOne iid
        $ [ Label "Gain 2 Resources" [TakeResources iid 2 (toAbilitySource attrs 1) False] | canGainResources ]
        <> [ Label "Spend 2 Resources to gain 1 clue" [SpendResources iid 2, GainClues iid 1] | hasTwoResources ]
      pure l
    _ -> TrophyRoom <$> runMessage msg attrs

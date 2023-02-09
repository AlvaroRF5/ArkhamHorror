module Arkham.Location.Cards.ChapultepecHill_178
  ( chapultepecHill_178
  , ChapultepecHill_178(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Helpers.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing

newtype ChapultepecHill_178 = ChapultepecHill_178 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

chapultepecHill_178 :: LocationCard ChapultepecHill_178
chapultepecHill_178 = locationWith
  ChapultepecHill_178
  Cards.chapultepecHill_178
  2
  (PerPlayer 2)
  (labelL .~ "triangle")

instance HasAbilities ChapultepecHill_178 where
  getAbilities (ChapultepecHill_178 attrs) = withBaseAbilities
    attrs
    [ mkAbility attrs 1
    $ ForcedAbility
    $ PutLocationIntoPlay Timing.After Anyone
    $ LocationWithId
    $ toId attrs
    , limitedAbility (GroupLimit PerRound 1)
    $ restrictedAbility
        attrs
        2
        (Here
        <> CluesOnThis (AtLeast $ Static 1)
        <> CanDiscoverCluesAt (LocationWithId $ toId attrs)
        <> InvestigatorExists
             (You <> HandWith (LengthIs $ AtLeast $ Static 3))
        )
    $ ActionAbility Nothing
    $ ActionCost 1
    <> DiscardHandCost
    ]

instance RunMessage ChapultepecHill_178 where
  runMessage msg l@(ChapultepecHill_178 attrs) = case msg of
    UseCardAbility _ (isSource attrs -> True) 1 _ _ -> do
      iids <- selectList $ investigatorAt (toId attrs)
      for_ iids $ \iid -> pushAll
        [ RandomDiscard iid (toAbilitySource attrs 1) AnyCard
        , RandomDiscard iid (toAbilitySource attrs 1) AnyCard
        ]
      pure l
    UseCardAbility iid (isSource attrs -> True) 2 _ _ -> do
      push $ InvestigatorDiscoverClues iid (toId attrs) 2 Nothing
      pure l
    _ -> ChapultepecHill_178 <$> runMessage msg attrs

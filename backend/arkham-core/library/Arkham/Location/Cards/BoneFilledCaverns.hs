module Arkham.Location.Cards.BoneFilledCaverns
  ( boneFilledCaverns
  , BoneFilledCaverns(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Direction
import Arkham.GameValue
import Arkham.Id
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message hiding ( RevealLocation )
import Arkham.Scenario.Deck
import Arkham.Scenarios.ThePallidMask.Helpers
import Arkham.SlotType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype Metadata = Metadata { affectedInvestigator :: Maybe InvestigatorId }
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

newtype BoneFilledCaverns = BoneFilledCaverns (LocationAttrs `With` Metadata)
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

boneFilledCaverns :: LocationCard BoneFilledCaverns
boneFilledCaverns = locationWith
  (BoneFilledCaverns . (`with` Metadata Nothing))
  Cards.boneFilledCaverns
  3
  (PerPlayer 2)
  NoSymbol
  []
  ((connectsToL .~ adjacentLocations)
  . (costToEnterUnrevealedL
    .~ Costs [ActionCost 1, GroupClueCost (PerPlayer 1) YourLocation]
    )
  )

instance HasModifiersFor BoneFilledCaverns where
  getModifiersFor _ (InvestigatorTarget iid) (BoneFilledCaverns (attrs `With` metadata))
    = case affectedInvestigator metadata of
      Just iid' | iid == iid' ->
        pure $ toModifiers attrs [FewerSlots HandSlot 1]
      _ -> pure []
  getModifiersFor _ _ _ = pure []

instance HasAbilities BoneFilledCaverns where
  getAbilities (BoneFilledCaverns (attrs `With` _)) = withBaseAbilities
    attrs
    [ restrictedAbility
        attrs
        1
        (AnyCriterion
          [ Negate
              (LocationExists
              $ LocationInDirection dir (LocationWithId $ toId attrs)
              )
          | dir <- [Below, RightOf]
          ]
        )
      $ ForcedAbility
      $ RevealLocation Timing.When Anyone
      $ LocationWithId
      $ toId attrs
    | locationRevealed attrs
    ]

instance RunMessage BoneFilledCaverns where
  runMessage msg l@(BoneFilledCaverns (attrs `With` metadata)) = case msg of
    Investigate iid lid _ _ _ False | lid == toId attrs -> do
      result <- runMessage msg attrs
      assetIds <-
        selectList
        $ AssetControlledBy (InvestigatorWithId iid)
        <> AssetInSlot HandSlot
      push (RefillSlots iid HandSlot assetIds)
      pure $ BoneFilledCaverns $ With result (Metadata $ Just iid)
    UseCardAbility iid (isSource attrs -> True) _ 1 _ -> do
      n <- countM (directionEmpty attrs) [Below, RightOf]
      push (DrawFromScenarioDeck iid CatacombsDeck (toTarget attrs) n)
      pure l
    DrewFromScenarioDeck _ _ (isTarget attrs -> True) cards -> do
      placements <- mapMaybeM (toMaybePlacement attrs) [Below, RightOf]
      pushAll $ concat $ zipWith ($) placements cards
      pure l
    SkillTestEnds _ -> pure $ BoneFilledCaverns $ With attrs (Metadata Nothing)
    _ -> BoneFilledCaverns . (`with` metadata) <$> runMessage msg attrs

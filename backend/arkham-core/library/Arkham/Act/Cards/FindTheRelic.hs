module Arkham.Act.Cards.FindTheRelic
  ( FindTheRelic(..)
  , findTheRelic
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Asset.Cards qualified as Assets
import Arkham.Classes
import Arkham.Criteria
import Arkham.Game.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Resolution
import Arkham.Scenarios.ThreadsOfFate.Helpers
import Arkham.Target

newtype FindTheRelic = FindTheRelic ActAttrs
  deriving anyclass IsAct
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

findTheRelic :: ActCard FindTheRelic
findTheRelic = act (3, A) FindTheRelic Cards.findTheRelic Nothing

instance HasModifiersFor FindTheRelic where
  getModifiersFor (LocationTarget lid) (FindTheRelic a) = do
    isModified <- lid
      <=~> LocationWithAsset (assetIs Assets.relicOfAgesADeviceOfSomeSort)
    pure $ toModifiers a [ ShroudModifier 2 | isModified ]
  getModifiersFor _ _ = pure []

instance HasAbilities FindTheRelic where
  getAbilities (FindTheRelic a) =
    [ restrictedAbility
          a
          1
          (LocationExists
          $ LocationWithAsset (assetIs Assets.relicOfAgesADeviceOfSomeSort)
          <> LocationWithoutClues
          )
        $ Objective
        $ ForcedAbility AnyWindow
    | onSide A a
    ]

instance RunMessage FindTheRelic where
  runMessage msg a@(FindTheRelic attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      push $ AdvanceAct (toId attrs) (toSource attrs) AdvancedWithOther
      pure a
    AdvanceAct aid _ _ | aid == actId attrs && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      deckCount <- getActDecksInPlayCount
      relicOfAges <- selectJust $ assetIs Assets.relicOfAgesADeviceOfSomeSort
      iids <- selectList $ NearestToLocation $ LocationWithAsset $ assetIs
        Assets.relicOfAgesADeviceOfSomeSort
      let
        takeControlMessage = chooseOrRunOne
          leadInvestigatorId
          [ targetLabel iid [TakeControlOfAsset iid relicOfAges] | iid <- iids ]
        nextMessage =
          if deckCount <= 1
            then ScenarioResolution $ Resolution 1
            else RemoveFromGame (ActTarget $ toId attrs)
      pushAll [takeControlMessage, nextMessage]
      pure a
    _ -> FindTheRelic <$> runMessage msg attrs

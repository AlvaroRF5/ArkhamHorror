module Arkham.Act.Cards.TheChamberOfStillRemains (
  TheChamberOfStillRemains (..),
  theChamberOfStillRemains,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Assets
import Arkham.Card
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Helpers.Ability
import Arkham.Helpers.Investigator
import Arkham.Helpers.Location
import Arkham.Helpers.Query
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Scenario.Deck

newtype TheChamberOfStillRemains = TheChamberOfStillRemains ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

instance HasAbilities TheChamberOfStillRemains where
  getAbilities (TheChamberOfStillRemains a) =
    withBaseAbilities
      a
      [ restrictedAbility a 1 (ScenarioDeckWithCard ExplorationDeck)
          $ ActionAbility (Just Action.Explore)
          $ ActionCost 1
      ]

theChamberOfStillRemains :: ActCard TheChamberOfStillRemains
theChamberOfStillRemains =
  act
    (2, A)
    TheChamberOfStillRemains
    Cards.theChamberOfStillRemains
    (Just $ GroupClueCost (PerPlayer 2) (LocationWithTitle "Chamber of Time"))

instance RunMessage TheChamberOfStillRemains where
  runMessage msg a@(TheChamberOfStillRemains attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      locationSymbols <- toConnections =<< getJustLocation iid
      push
        $ Explore
          iid
          source
          (CardWithOneOf $ map CardWithPrintedLocationSymbol locationSymbols)
      pure a
    AdvanceAct aid _ _ | aid == actId attrs && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      chamberOfTime <- selectJust $ locationIs Locations.chamberOfTime
      relicOfAges <- selectJust $ assetIs Assets.relicOfAgesRepossessThePast
      investigators <- selectList $ investigatorAt chamberOfTime
      yig <- genCard Enemies.yig
      createYig <- createEnemyAt_ yig chamberOfTime Nothing
      pushAll
        $ [ chooseOrRunOne
              leadInvestigatorId
              [ targetLabel iid [TakeControlOfAsset iid relicOfAges]
              | iid <- investigators
              ]
          , createYig
          , AddToVictory (toTarget attrs)
          , AdvanceActDeck (actDeckId attrs) (toSource attrs)
          ]
      pure a
    _ -> TheChamberOfStillRemains <$> runMessage msg attrs

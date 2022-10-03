module Arkham.Act.Cards.HarlansCurseHarlanEarnstone
  ( HarlansCurseHarlanEarnstone(..)
  , harlansCurseHarlanEarnstone
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards qualified as Acts
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Asset.Cards qualified as Assets
import Arkham.Card
import Arkham.Card.EncounterCard
import Arkham.Classes
import Arkham.Criteria
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Helpers.Query
import Arkham.Id
import Arkham.Matcher hiding ( AssetCard )
import Arkham.Message
import Arkham.Placement
import Arkham.Source

newtype HarlansCurseHarlanEarnstone = HarlansCurseHarlanEarnstone ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

harlansCurseHarlanEarnstone :: ActCard HarlansCurseHarlanEarnstone
harlansCurseHarlanEarnstone = act
  (2, A)
  HarlansCurseHarlanEarnstone
  Cards.harlansCurseHarlanEarnstone
  Nothing

instance HasAbilities HarlansCurseHarlanEarnstone where
  getAbilities (HarlansCurseHarlanEarnstone a) =
    [ restrictedAbility
          a
          1
          (AssetExists $ assetIs Assets.harlanEarnstone <> AssetWithClues
            (AtLeast $ PerPlayer 1)
          )
        $ Objective
        $ ForcedAbility AnyWindow
    | onSide A a
    ]

instance RunMessage HarlansCurseHarlanEarnstone where
  runMessage msg a@(HarlansCurseHarlanEarnstone attrs) = case msg of
    UseCardAbility _ (isSource attrs -> True) 1 _ _ -> do
      push $ AdvanceAct (toId attrs) (toSource attrs) AdvancedWithOther
      pure a
    AdvanceAct aid _ _ | aid == actId attrs && onSide B attrs -> do
      harlan <- selectJust $ assetIs Assets.harlanEarnstone
      harlansLocation <- selectJust $ LocationWithAsset $ AssetWithId harlan
      let
        harlanEarnstoneCrazedByTheCurse = EncounterCard $ lookupEncounterCard
          Enemies.harlanEarnstoneCrazedByTheCurse
          (unAssetId harlan)
      pushAll
        [ CreateEnemyAt harlanEarnstoneCrazedByTheCurse harlansLocation Nothing
        , Flipped (AssetSource harlan) harlanEarnstoneCrazedByTheCurse
        , NextAdvanceActStep aid 1
        , AdvanceToAct (actDeckId attrs) Acts.recoverTheRelic A (toSource attrs)
        ]
      pure a
    NextAdvanceActStep aid 1 | aid == actId attrs && onSide B attrs -> do
      relicOfAges <- getSetAsideCard Assets.relicOfAgesADeviceOfSomeSort
      harlan <- selectJust $ enemyIs Enemies.harlanEarnstoneCrazedByTheCurse
      pushAll [CreateAssetAt relicOfAges (AttachedToEnemy harlan)]
      pure a
    _ -> HarlansCurseHarlanEarnstone <$> runMessage msg attrs

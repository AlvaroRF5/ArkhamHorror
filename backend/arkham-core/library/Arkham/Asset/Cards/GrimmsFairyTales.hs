module Arkham.Asset.Cards.GrimmsFairyTales
  ( grimmsFairyTales
  , GrimmsFairyTales(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Damage
import Arkham.GameValue
import Arkham.Helpers.Investigator
import Arkham.Id
import Arkham.Matcher
import Arkham.Timing qualified as Timing
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window

newtype GrimmsFairyTales = GrimmsFairyTales AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

grimmsFairyTales :: AssetCard GrimmsFairyTales
grimmsFairyTales = asset GrimmsFairyTales Cards.grimmsFairyTales

instance HasAbilities GrimmsFairyTales where
  getAbilities (GrimmsFairyTales a) =
    [ restrictedAbility a 1 ControlsThis
        $ ReactionAbility
            (SkillTestResult
                Timing.After
                (HealableInvestigator
                  (toSource a)
                  HorrorType
                  (InvestigatorAt YourLocation)
                )
                AnySkillTest
            $ FailureResult
            $ AtLeast
            $ Static 2
            )
        $ ExhaustCost (toTarget a)
        <> UseCost (AssetWithId $ toId a) Secret 1
    ]

toInvestigator :: [Window] -> InvestigatorId
toInvestigator [] = error "invalid call"
toInvestigator (Window _ (Window.FailSkillTest iid _) : _) = iid
toInvestigator (_ : xs) = toInvestigator xs

instance RunMessage GrimmsFairyTales where
  runMessage msg a@(GrimmsFairyTales attrs) = case msg of
    UseCardAbility _ source 1 windows' _ | isSource attrs source -> do
      mHealHorror <- getHealHorrorMessage attrs 1 (toInvestigator windows')
      for_ mHealHorror push
      pure a
    _ -> GrimmsFairyTales <$> runMessage msg attrs

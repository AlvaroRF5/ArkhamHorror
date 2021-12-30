module Arkham.Asset.Cards.ClarityOfMind
  ( clarityOfMind
  , ClarityOfMind(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Target

newtype ClarityOfMind = ClarityOfMind AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

clarityOfMind :: AssetCard ClarityOfMind
clarityOfMind = asset ClarityOfMind Cards.clarityOfMind

instance HasAbilities ClarityOfMind where
  getAbilities (ClarityOfMind a) =
    [ restrictedAbility
          a
          1
          (OwnsThis <> InvestigatorExists
            (InvestigatorAt YourLocation <> InvestigatorWithAnyHorror)
          )
        $ ActionAbility Nothing
        $ Costs [ActionCost 1, UseCost (toId a) Charge 1]
    ]

instance AssetRunner env => RunMessage env ClarityOfMind where
  runMessage msg a@(ClarityOfMind attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      targets <- selectListMap InvestigatorTarget (InvestigatorAt YourLocation)
      a <$ push
        (chooseOrRunOne
          iid
          [ TargetLabel target [HealHorror target 1] | target <- targets ]
        )
    _ -> ClarityOfMind <$> runMessage msg attrs

module Arkham.Types.Asset.Cards.Burglary
  ( Burglary(..)
  , burglary
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Window

newtype Burglary = Burglary AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

burglary :: AssetCard Burglary
burglary = asset Burglary Cards.burglary

instance HasModifiersFor env Burglary

instance HasAbilities env Burglary where
  getAbilities iid (Window Timing.When NonFast) (Burglary a) | ownedBy a iid =
    pure
      [ mkAbility a 1 $ ActionAbility (Just Action.Investigate) $ Costs
          [ActionCost 1, ExhaustCost (toTarget a)]
      ]
  getAbilities _ _ _ = pure []

instance AssetRunner env => RunMessage env Burglary where
  runMessage msg a@(Burglary attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      lid <- getId iid
      a <$ push
        (CreateEffect "01045" Nothing source (InvestigationTarget iid lid))
    _ -> Burglary <$> runMessage msg attrs

module Arkham.Types.Asset.Cards.Burglary
  ( Burglary(..)
  , burglary
  ) where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner

newtype Burglary = Burglary Attrs
  deriving newtype (Show, ToJSON, FromJSON)

burglary :: AssetId -> Burglary
burglary uuid = Burglary $ baseAttrs uuid "01045"

instance HasModifiersFor env Burglary where
  getModifiersFor = noModifiersFor

instance HasActions env Burglary where
  getActions iid NonFast (Burglary a) | ownedBy a iid = pure
    [ assetAction iid a 1 (Just Action.Investigate)
        $ Costs [ActionCost 1, ExhaustCost (toTarget a)]
    ]
  getActions _ _ _ = pure []

instance AssetRunner env => RunMessage env Burglary where
  runMessage msg a@(Burglary attrs@Attrs {..}) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      lid <- getId iid
      a <$ unshiftMessage
        (CreateEffect "01045" Nothing source (InvestigationTarget iid lid))
    _ -> Burglary <$> runMessage msg attrs

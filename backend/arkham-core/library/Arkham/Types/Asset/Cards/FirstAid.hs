module Arkham.Types.Asset.Cards.FirstAid
  ( FirstAid(..)
  , firstAid
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Asset.Uses
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Window

newtype FirstAid = FirstAid AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

firstAid :: AssetCard FirstAid
firstAid = assetWith FirstAid Cards.firstAid (startingUsesL ?~ Uses Supply 3)

instance HasModifiersFor env FirstAid

ability :: AssetAttrs -> Ability
ability attrs = mkAbility
  (toSource attrs)
  1
  (ActionAbility Nothing $ Costs [ActionCost 1, UseCost (toId attrs) Supply 1])

instance HasActions env FirstAid where
  getActions iid NonFast (FirstAid a) =
    pure [ UseAbility iid (ability a) | ownedBy a iid ]
  getActions _ _ _ = pure []

instance AssetRunner env => RunMessage env FirstAid where
  runMessage msg a@(FirstAid attrs@AssetAttrs {..}) = case msg of
    UseCardAbility iid (AssetSource aid) _ 1 _ | aid == assetId -> do
      lid <- getId @LocationId iid
      investigatorTargets <- map InvestigatorTarget <$> getSetList lid
      a <$ push
        (chooseOne
          iid
          [ TargetLabel
              target
              [chooseOne iid [HealDamage target 1, HealHorror target 1]]
          | target <- investigatorTargets
          ]
        )
    _ -> FirstAid <$> runMessage msg attrs

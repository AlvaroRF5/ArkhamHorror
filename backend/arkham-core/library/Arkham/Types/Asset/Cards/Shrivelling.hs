module Arkham.Types.Asset.Cards.Shrivelling
  ( Shrivelling(..)
  , shrivelling
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Asset.Uses
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Window

newtype Shrivelling = Shrivelling AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

shrivelling :: AssetCard Shrivelling
shrivelling = arcane Shrivelling Cards.shrivelling

instance HasModifiersFor env Shrivelling

instance HasAbilities env Shrivelling where
  getAbilities iid NonFast (Shrivelling a) | ownedBy a iid = do
    pure
      [ mkAbility a 1 $ ActionAbilityWithSkill
          (Just Action.Fight)
          SkillWillpower
          (Costs [ActionCost 1, UseCost (toId a) Charge 1])
      ]
  getAbilities _ _ _ = pure []

instance AssetRunner env => RunMessage env Shrivelling where
  runMessage msg a@(Shrivelling attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifiers attrs (InvestigatorTarget iid) [DamageDealt 1]
      , CreateEffect "01060" Nothing source (InvestigatorTarget iid)
      , ChooseFightEnemy iid source SkillWillpower mempty False
      ]
    _ -> Shrivelling <$> runMessage msg attrs

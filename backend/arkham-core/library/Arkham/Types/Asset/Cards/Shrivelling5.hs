module Arkham.Types.Asset.Cards.Shrivelling5
  ( Shrivelling5(..)
  , shrivelling5
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
import Arkham.Types.EffectMetadata
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Window

newtype Shrivelling5 = Shrivelling5 AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

shrivelling5 :: AssetCard Shrivelling5
shrivelling5 = arcane Shrivelling5 Cards.shrivelling5

instance HasModifiersFor env Shrivelling5

instance HasAbilities env Shrivelling5 where
  getAbilities iid NonFast (Shrivelling5 a) | ownedBy a iid = pure
    [ mkAbility a 1 $ ActionAbility
        (Just Action.Fight)
        (Costs [ActionCost 1, UseCost (toId a) Charge 1])
    ]
  getAbilities _ _ _ = pure []

instance AssetRunner env => RunMessage env Shrivelling5 where
  runMessage msg a@(Shrivelling5 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifiers
        attrs
        (InvestigatorTarget iid)
        [SkillModifier SkillWillpower 3, DamageDealt 2]
      , CreateEffect
        "01060"
        (Just $ EffectInt 2)
        source
        (InvestigatorTarget iid)
      -- ^ reusing shrivelling(0)'s effect with a damage override
      , ChooseFightEnemy iid source SkillWillpower mempty False
      ]
    _ -> Shrivelling5 <$> runMessage msg attrs

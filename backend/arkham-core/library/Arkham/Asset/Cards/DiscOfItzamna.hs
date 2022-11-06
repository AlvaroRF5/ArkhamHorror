module Arkham.Asset.Cards.DiscOfItzamna where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.DamageEffect
import Arkham.Matcher hiding ( EnemyEvaded, NonAttackDamageEffect )
import Arkham.Timing qualified as Timing
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window

newtype DiscOfItzamna = DiscOfItzamna AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

discOfItzamna :: AssetCard DiscOfItzamna
discOfItzamna = asset DiscOfItzamna Cards.discOfItzamna

instance HasAbilities DiscOfItzamna where
  getAbilities (DiscOfItzamna a) =
    [ restrictedAbility a 1 ControlsThis
        $ ReactionAbility
            (EnemySpawns Timing.When YourLocation NonEliteEnemy)
            Free
    ]

instance RunMessage DiscOfItzamna where
  runMessage msg a@(DiscOfItzamna attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 (map windowType -> [Window.EnemySpawns eid _]) _
      -> do
        pushAll
          [ EnemyEvaded iid eid
          , EnemyDamage eid iid (toSource attrs) NonAttackDamageEffect 2
          ]
        pure a
    _ -> DiscOfItzamna <$> runMessage msg attrs

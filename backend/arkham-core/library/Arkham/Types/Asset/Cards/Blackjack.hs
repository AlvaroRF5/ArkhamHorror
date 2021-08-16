module Arkham.Types.Asset.Cards.Blackjack
  ( blackjack
  , Blackjack(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype Blackjack = Blackjack AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

blackjack :: AssetCard Blackjack
blackjack = hand Blackjack Cards.blackjack

instance HasAbilities env Blackjack where
  getAbilities _ _ (Blackjack a) = pure
    [ restrictedAbility a 1 OwnsThis
        $ ActionAbility (Just Action.Fight) (ActionCost 1)
    ]

instance AssetRunner env => RunMessage env Blackjack where
  runMessage msg a@(Blackjack attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifiers
        attrs
        (InvestigatorTarget iid)
        [SkillModifier SkillCombat 1, DoesNotDamageOtherInvestigator]
      , ChooseFightEnemy iid source SkillCombat mempty False
      ]
    _ -> Blackjack <$> runMessage msg attrs

module Arkham.Asset.Cards.Blackjack
  ( blackjack
  , Blackjack(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Asset.Attrs
import Arkham.Cost
import Arkham.Criteria
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target

newtype Blackjack = Blackjack AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

blackjack :: AssetCard Blackjack
blackjack = asset Blackjack Cards.blackjack

instance HasAbilities Blackjack where
  getAbilities (Blackjack a) =
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
      , ChooseFightEnemy iid source Nothing SkillCombat mempty False
      ]
    _ -> Blackjack <$> runMessage msg attrs

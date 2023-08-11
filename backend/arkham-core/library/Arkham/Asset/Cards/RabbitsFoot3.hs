module Arkham.Asset.Cards.RabbitsFoot3 (
  RabbitsFoot3 (..),
  rabbitsFoot3,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Matcher
import Arkham.Timing qualified as Timing
import Arkham.Window (Window (..))
import Arkham.Window qualified as Window

newtype RabbitsFoot3 = RabbitsFoot3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rabbitsFoot3 :: AssetCard RabbitsFoot3
rabbitsFoot3 = asset RabbitsFoot3 Cards.rabbitsFoot3

instance HasAbilities RabbitsFoot3 where
  getAbilities (RabbitsFoot3 a) =
    [ restrictedAbility a 1 ControlsThis $
        ReactionAbility
          (SkillTestResult Timing.After You AnySkillTest (FailureResult AnyValue))
          (ExhaustCost $ toTarget a)
    ]

instance RunMessage RabbitsFoot3 where
  runMessage msg a@(RabbitsFoot3 attrs) = case msg of
    UseCardAbility iid source 1 [Window _ (Window.FailSkillTest _ x)] _
      | isSource attrs source ->
          a
            <$ push
              ( Search
                  iid
                  source
                  (InvestigatorTarget iid)
                  [fromTopOfDeck x]
                  AnyCard
                  (DrawFound iid 1)
              )
    _ -> RabbitsFoot3 <$> runMessage msg attrs

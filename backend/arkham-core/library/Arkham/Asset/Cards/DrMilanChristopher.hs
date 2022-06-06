module Arkham.Asset.Cards.DrMilanChristopher where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype DrMilanChristopher = DrMilanChristopher AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drMilanChristopher :: AssetCard DrMilanChristopher
drMilanChristopher = ally DrMilanChristopher Cards.drMilanChristopher (1, 2)

instance HasModifiersFor env DrMilanChristopher where
  getModifiersFor _ (InvestigatorTarget iid) (DrMilanChristopher a) =
    pure [ toModifier a (SkillModifier SkillIntellect 1) | controlledBy a iid ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities DrMilanChristopher where
  getAbilities (DrMilanChristopher x) =
    [ restrictedAbility x 1 OwnsThis $ ReactionAbility
        (SkillTestResult Timing.After You (WhileInvestigating Anywhere)
        $ SuccessResult AnyValue
        )
        Free
    ]

instance RunMessage DrMilanChristopher where
  runMessage msg a@(DrMilanChristopher attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (TakeResources iid 1 False)
    _ -> DrMilanChristopher <$> runMessage msg attrs

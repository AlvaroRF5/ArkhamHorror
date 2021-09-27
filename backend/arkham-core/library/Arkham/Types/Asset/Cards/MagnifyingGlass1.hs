module Arkham.Types.Asset.Cards.MagnifyingGlass1 where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Ability
import Arkham.Types.Action qualified as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype MagnifyingGlass1 = MagnifyingGlass1 AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

magnifyingGlass1 :: AssetCard MagnifyingGlass1
magnifyingGlass1 = hand MagnifyingGlass1 Cards.magnifyingGlass1

instance HasModifiersFor env MagnifyingGlass1 where
  getModifiersFor _ (InvestigatorTarget iid) (MagnifyingGlass1 a) = pure
    [ toModifier a $ ActionSkillModifier Action.Investigate SkillIntellect 1
    | ownedBy a iid
    ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities MagnifyingGlass1 where
  getAbilities (MagnifyingGlass1 a) =
    [ restrictedAbility
          a
          1
          (OwnsThis <> LocationExists (YourLocation <> LocationWithoutClues))
        $ FastAbility Free
    ]

instance (AssetRunner env) => RunMessage env MagnifyingGlass1 where
  runMessage msg a@(MagnifyingGlass1 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (ReturnToHand iid (toTarget attrs))
    _ -> MagnifyingGlass1 <$> runMessage msg attrs

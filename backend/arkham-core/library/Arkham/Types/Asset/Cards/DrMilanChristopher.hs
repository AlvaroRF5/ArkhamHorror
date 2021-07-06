module Arkham.Types.Asset.Cards.DrMilanChristopher where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Window

newtype DrMilanChristopher = DrMilanChristopher AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drMilanChristopher :: AssetCard DrMilanChristopher
drMilanChristopher = ally DrMilanChristopher Cards.drMilanChristopher (1, 2)

instance HasModifiersFor env DrMilanChristopher where
  getModifiersFor _ (InvestigatorTarget iid) (DrMilanChristopher a) =
    pure [ toModifier a (SkillModifier SkillIntellect 1) | ownedBy a iid ]
  getModifiersFor _ _ _ = pure []

instance HasActions env DrMilanChristopher where
  getActions i (AfterSuccessfulInvestigation You _) (DrMilanChristopher x)
    | ownedBy x i = pure
      [UseAbility i (mkAbility (toSource x) 1 (ReactionAbility Free))]
  getActions i window (DrMilanChristopher x) = getActions i window x

instance AssetRunner env => RunMessage env DrMilanChristopher where
  runMessage msg a@(DrMilanChristopher attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (TakeResources iid 1 False)
    _ -> DrMilanChristopher <$> runMessage msg attrs

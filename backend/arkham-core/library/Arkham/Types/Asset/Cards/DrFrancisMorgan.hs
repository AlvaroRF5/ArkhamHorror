module Arkham.Types.Asset.Cards.DrFrancisMorgan
  ( drFrancisMorgan
  , DrFrancisMorgan(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Window

newtype DrFrancisMorgan = DrFrancisMorgan AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drFrancisMorgan :: AssetCard DrFrancisMorgan
drFrancisMorgan = ally DrFrancisMorgan Cards.drFrancisMorgan (4, 1)

ability :: AssetAttrs -> Ability
ability attrs =
  mkAbility (toSource attrs) 1 (ResponseAbility $ ExhaustCost (toTarget attrs))

instance HasAbilities env DrFrancisMorgan where
  getAbilities iid (AfterEnemyDefeated who _) (DrFrancisMorgan attrs)
    | iid == who = pure [ ability attrs | ownedBy attrs iid ]
  getAbilities iid window (DrFrancisMorgan attrs) = getAbilities iid window attrs

instance HasModifiersFor env DrFrancisMorgan where
  getModifiersFor _ (InvestigatorTarget iid) (DrFrancisMorgan a) =
    pure [ toModifier a (SkillModifier SkillCombat 1) | ownedBy a iid ]
  getModifiersFor _ _ _ = pure []

instance (HasQueue env, HasModifiersFor env ()) => RunMessage env DrFrancisMorgan where
  runMessage msg a@(DrFrancisMorgan attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (DrawCards iid 1 False)
    _ -> DrFrancisMorgan <$> runMessage msg attrs

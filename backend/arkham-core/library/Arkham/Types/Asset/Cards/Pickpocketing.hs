module Arkham.Types.Asset.Cards.Pickpocketing
  ( Pickpocketing(..)
  , pickpocketing
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.Window

newtype Pickpocketing = Pickpocketing AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

pickpocketing :: AssetCard Pickpocketing
pickpocketing = asset Pickpocketing Cards.pickpocketing

instance HasModifiersFor env Pickpocketing

instance HasActions env Pickpocketing where
  getActions iid (WhenEnemyEvaded You) (Pickpocketing a) =
    withBaseActions iid (WhenEnemyEvaded You) a $ do
      let
        ability =
          mkAbility (toSource a) 1 (ReactionAbility $ ExhaustCost (toTarget a))
      pure [ UseAbility iid ability | ownedBy a iid ]
  getActions i window (Pickpocketing a) = getActions i window a

instance AssetRunner env => RunMessage env Pickpocketing where
  runMessage msg a@(Pickpocketing attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push (DrawCards iid 1 False)
    _ -> Pickpocketing <$> runMessage msg attrs

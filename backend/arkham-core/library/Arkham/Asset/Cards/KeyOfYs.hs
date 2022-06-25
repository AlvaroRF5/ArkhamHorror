module Arkham.Asset.Cards.KeyOfYs
  ( keyOfYs
  , KeyOfYs(..)
  )
where

import Arkham.Prelude

import Arkham.Ability
import qualified Arkham.Asset.Cards as Cards
import Arkham.Asset.Runner
import Arkham.Criteria
import Arkham.Matcher
import Arkham.GameValue
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype KeyOfYs = KeyOfYs AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

keyOfYs :: AssetCard KeyOfYs
keyOfYs =
  assetWith KeyOfYs Cards.keyOfYs (sanityL ?~ 4)

instance HasModifiersFor KeyOfYs where
  getModifiersFor _ (InvestigatorTarget iid) (KeyOfYs a) = 
    pure [ toModifier a (AnySkillValue $ assetHorror a) | controlledBy a iid ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities KeyOfYs where
  getAbilities (KeyOfYs x) =
    [ restrictedAbility x 1 OwnsThis
        $ ForcedAbility
        $ PlacedCounter Timing.When You HorrorCounter (AtLeast $ Static 1)
    , restrictedAbility x 2 OwnsThis
        $ ForcedAbility
        $ AssetLeavesPlay Timing.When
        $ AssetWithId
        $ toId x
    ]

instance RunMessage KeyOfYs where
  runMessage msg a@(KeyOfYs attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ MovedHorror source (InvestigatorTarget iid) 1
      pure . KeyOfYs $ attrs & horrorL +~ 1
    UseCardAbility iid source _ 2 _ | isSource attrs source -> do
      push $ DiscardTopOfDeck iid 10 Nothing
      pure a
    _ -> KeyOfYs <$> runMessage msg attrs

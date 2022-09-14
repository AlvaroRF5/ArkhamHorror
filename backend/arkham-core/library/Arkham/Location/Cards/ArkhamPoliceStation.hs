module Arkham.Location.Cards.ArkhamPoliceStation
  ( arkhamPoliceStation
  , ArkhamPoliceStation(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Game.Helpers
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Target
import Arkham.Trait

newtype ArkhamPoliceStation = ArkhamPoliceStation LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arkhamPoliceStation :: LocationCard ArkhamPoliceStation
arkhamPoliceStation =
  location ArkhamPoliceStation Cards.arkhamPoliceStation 3 (PerPlayer 2)

instance HasModifiersFor ArkhamPoliceStation where
  getModifiersFor (LocationTarget lid) (ArkhamPoliceStation a) = do
    isEasttown <- lid <=~> locationIs Cards.easttown
    pure $ toModifiers
      a
      [ ConnectedToWhen (LocationWithId lid) (LocationWithId $ toId a)
      | isEasttown
      ]
  getModifiersFor _ _ = pure []

instance HasAbilities ArkhamPoliceStation where
  getAbilities (ArkhamPoliceStation attrs) = withBaseAbilities
    attrs
    [ restrictedAbility attrs 1 Here $ ActionAbility Nothing $ ActionCost 1
    | locationRevealed attrs
    ]

instance RunMessage ArkhamPoliceStation where
  runMessage msg l@(ArkhamPoliceStation attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ Search
        iid
        source
        (InvestigatorTarget iid)
        [fromTopOfDeck 6]
        (CardWithTrait Weapon)
        (DrawFound iid 1)
      pure l
    _ -> ArkhamPoliceStation <$> runMessage msg attrs

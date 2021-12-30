module Arkham.Location.Cards.GreenRoom
  ( greenRoom
  , GreenRoom(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Message
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target

newtype GreenRoom = GreenRoom LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

greenRoom :: LocationCard GreenRoom
greenRoom = location GreenRoom Cards.greenRoom 5 (PerPlayer 1) Plus [Triangle]

instance HasAbilities GreenRoom where
  getAbilities (GreenRoom attrs) = withBaseAbilities
    attrs
    [ restrictedAbility attrs 1 Here
      $ ActionAbility (Just Action.Investigate)
      $ ActionCost 1
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage env GreenRoom where
  runMessage msg l@(GreenRoom attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> l <$ pushAll
      [ skillTestModifier
        source
        (InvestigatorTarget iid)
        (SkillModifier SkillIntellect 3)
      , Investigate iid (toId attrs) source Nothing SkillIntellect False
      , DiscardHand iid
      ]
    _ -> GreenRoom <$> runMessage msg attrs

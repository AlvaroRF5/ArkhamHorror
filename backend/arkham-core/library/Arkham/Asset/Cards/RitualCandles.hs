module Arkham.Asset.Cards.RitualCandles
  ( ritualCandles
  , RitualCandles(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Token

newtype RitualCandles = RitualCandles AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ritualCandles :: AssetCard RitualCandles
ritualCandles = asset RitualCandles Cards.ritualCandles

instance HasAbilities RitualCandles where
  getAbilities (RitualCandles x) =
    [ restrictedAbility
        x
        1
        OwnsThis
        (ReactionAbility
          (RevealChaosToken
            Timing.When
            You
            (TokenMatchesAny
            $ map TokenFaceIs [Skull, Cultist, Tablet, ElderThing]
            )
          )
          Free
        )
    ]

instance RunMessage RitualCandles where
  runMessage msg a@(RitualCandles attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [skillTestModifier attrs (InvestigatorTarget iid) (AnySkillValue 1)]
    _ -> RitualCandles <$> runMessage msg attrs

module Arkham.Types.Asset.Cards.RitualCandles
  ( ritualCandles
  , RitualCandles(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Token

newtype RitualCandles = RitualCandles AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ritualCandles :: AssetCard RitualCandles
ritualCandles = hand RitualCandles Cards.ritualCandles

instance HasAbilities env RitualCandles where
  getAbilities _ _ (RitualCandles x) = pure
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

instance AssetRunner env => RunMessage env RitualCandles where
  runMessage msg a@(RitualCandles attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [skillTestModifier attrs (InvestigatorTarget iid) (AnySkillValue 1)]
    _ -> RitualCandles <$> runMessage msg attrs

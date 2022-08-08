module Arkham.Effect.Effects.UncageTheSoul
  ( UncageTheSoul(..)
  , uncageTheSoul
  ) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Game.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype UncageTheSoul = UncageTheSoul EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

uncageTheSoul :: EffectArgs -> UncageTheSoul
uncageTheSoul = UncageTheSoul . uncurry4 (baseAttrs "03033")

instance HasModifiersFor UncageTheSoul where
  getModifiersFor target@(CardTarget card) (UncageTheSoul attrs)
    | effectTarget attrs == target = pure
    $ toModifiers attrs [ReduceCostOf (CardWithId $ toCardId card) 3]
  getModifiersFor _ _ = pure []

instance RunMessage UncageTheSoul where
  runMessage msg e@(UncageTheSoul attrs) = case msg of
    ResolvedCard _ card | CardTarget card == effectTarget attrs ->
      e <$ push (DisableEffect $ toId attrs)
    _ -> UncageTheSoul <$> runMessage msg attrs

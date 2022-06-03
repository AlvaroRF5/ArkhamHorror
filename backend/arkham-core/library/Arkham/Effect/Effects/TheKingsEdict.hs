module Arkham.Effect.Effects.TheKingsEdict
  ( TheKingsEdict(..)
  , theKingsEdict
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Effect.Attrs
import Arkham.Game.Helpers
import Arkham.Id
import Arkham.Message
import Arkham.Modifier
import Arkham.Query
import Arkham.Target

newtype TheKingsEdict = TheKingsEdict EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theKingsEdict :: EffectArgs -> TheKingsEdict
theKingsEdict = TheKingsEdict . uncurry4 (baseAttrs "03100")

instance
  ( HasCount DoomCount env EnemyId
  , HasCount ClueCount env EnemyId
  )
  => HasModifiersFor env TheKingsEdict where
  getModifiersFor _ target@(EnemyTarget eid) (TheKingsEdict a)
    | target == effectTarget a = do
      clueCount <- unClueCount <$> getCount eid
      doomCount <- unDoomCount <$> getCount eid
      pure $ toModifiers
        a
        [ EnemyFight (clueCount + doomCount) | clueCount + doomCount > 0 ]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage TheKingsEdict where
  runMessage msg e@(TheKingsEdict attrs) = case msg of
    EndRound -> e <$ push (DisableEffect $ toId e)
    _ -> TheKingsEdict <$> runMessage msg attrs

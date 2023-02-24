module Arkham.Effect.Effects.MeatCleaver
  ( MeatCleaver(..)
  , meatCleaver
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Helpers.Investigator
import Arkham.Message

newtype MeatCleaver = MeatCleaver EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

meatCleaver :: EffectArgs -> MeatCleaver
meatCleaver = MeatCleaver . uncurry4 (baseAttrs "05114")

instance RunMessage MeatCleaver where
  runMessage msg e@(MeatCleaver attrs) = case msg of
    EnemyDefeated _ _ source _ | effectSource attrs == source -> do
      case effectTarget attrs of
        InvestigatorTarget iid -> do
          mHealHorror <- getHealHorrorMessage source 1 iid
          pushAll
            $ maybeToList mHealHorror
            <> [DisableEffect $ toId attrs]
          pure e
        _ -> error "Invalid target"
    SkillTestEnds _ _ -> e <$ push (DisableEffect $ toId attrs)
    _ -> MeatCleaver <$> runMessage msg attrs

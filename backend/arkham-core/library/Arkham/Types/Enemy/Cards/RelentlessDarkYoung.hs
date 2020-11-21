{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Cards.RelentlessDarkYoung where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner

newtype RelentlessDarkYoung = RelentlessDarkYoung Attrs
  deriving newtype (Show, ToJSON, FromJSON)

relentlessDarkYoung :: EnemyId -> RelentlessDarkYoung
relentlessDarkYoung uuid =
  RelentlessDarkYoung
    $ baseAttrs uuid "01179"
    $ (healthDamageL .~ 2)
    . (sanityDamageL .~ 1)
    . (fightL .~ 4)
    . (healthL .~ Static 5)
    . (evadeL .~ 2)
    . (preyL .~ LowestSkill SkillAgility)

instance HasModifiersFor env RelentlessDarkYoung where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env RelentlessDarkYoung where
  getActions i window (RelentlessDarkYoung attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env RelentlessDarkYoung where
  runMessage msg (RelentlessDarkYoung attrs) = case msg of
    EndRound ->
      pure $ RelentlessDarkYoung $ attrs & damageL %~ max 0 . subtract 2
    _ -> RelentlessDarkYoung <$> runMessage msg attrs

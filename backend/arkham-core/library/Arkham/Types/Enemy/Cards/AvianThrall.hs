{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Enemy.Cards.AvianThrall
  ( AvianThrall(..)
  , avianThrall
  )
where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.Game.Helpers
import Arkham.Types.Trait

newtype AvianThrall = AvianThrall Attrs
  deriving newtype (Show, ToJSON, FromJSON)

avianThrall :: EnemyId -> AvianThrall
avianThrall uuid =
  AvianThrall
    $ baseAttrs uuid "02094"
    $ (healthDamageL .~ 1)
    . (sanityDamageL .~ 1)
    . (fightL .~ 5)
    . (healthL .~ Static 4)
    . (evadeL .~ 3)

instance HasSet Trait env AssetId => HasModifiersFor env AvianThrall where
  getModifiersFor (AssetSource aid) target (AvianThrall attrs)
    | isTarget attrs target = do
      traits <- getSet aid
      pure $ toModifiers
        attrs
        [ EnemyFight (-3) | any (`elem` [Ranged, Firearm, Spell]) traits ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env AvianThrall where
  getActions i window (AvianThrall attrs) = getActions i window attrs

instance EnemyRunner env => RunMessage env AvianThrall where
  runMessage msg (AvianThrall attrs@Attrs {..}) =
    AvianThrall <$> runMessage msg attrs

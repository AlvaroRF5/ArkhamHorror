{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Cards.TheMaskedHunter where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner

newtype TheMaskedHunter = TheMaskedHunter Attrs
  deriving newtype (Show, ToJSON, FromJSON)

theMaskedHunter :: EnemyId -> TheMaskedHunter
theMaskedHunter uuid =
  TheMaskedHunter
    $ baseAttrs uuid "01121b"
    $ (healthDamageL .~ 2)
    . (sanityDamageL .~ 1)
    . (fightL .~ 4)
    . (healthL .~ Static 4)
    . (evadeL .~ 2)
    . (preyL .~ MostClues)
    . (uniqueL .~ True)

instance HasModifiersFor env TheMaskedHunter where
  getModifiersFor _ (InvestigatorTarget iid) (TheMaskedHunter Attrs {..}) =
    if iid `elem` enemyEngagedInvestigators
      then pure [CannotDiscoverClues, CannotSpendClues]
      else pure []
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env TheMaskedHunter where
  getActions i window (TheMaskedHunter attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env TheMaskedHunter where
  runMessage msg (TheMaskedHunter attrs@Attrs {..}) = case msg of
    EnemySpawnEngagedWithPrey eid | eid == enemyId -> do
      playerCount <- unPlayerCount <$> getCount ()
      TheMaskedHunter
        <$> runMessage msg (attrs & healthL %~ fmap (+ (2 * playerCount)))
    _ -> TheMaskedHunter <$> runMessage msg attrs

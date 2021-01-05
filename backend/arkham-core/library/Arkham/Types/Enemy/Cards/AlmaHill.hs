module Arkham.Types.Enemy.Cards.AlmaHill
  ( AlmaHill(..)
  , almaHill
  )
where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.Game.Helpers

newtype AlmaHill = AlmaHill Attrs
  deriving newtype (Show, ToJSON, FromJSON)

almaHill :: EnemyId -> AlmaHill
almaHill uuid =
  AlmaHill
    $ baseAttrs uuid "50046"
    $ (sanityDamageL .~ 2)
    . (fightL .~ 3)
    . (healthL .~ Static 3)
    . (evadeL .~ 3)
    . (uniqueL .~ True)

instance HasModifiersFor env AlmaHill where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env AlmaHill where
  getActions iid NonFast (AlmaHill attrs@Attrs {..}) =
    withBaseActions iid NonFast attrs $ do
      locationId <- getId @LocationId iid
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility
              (EnemySource enemyId)
              1
              (ActionAbility (Just Parley) (ActionCost 1))
            )
        | locationId == enemyLocation
        ]
  getActions _ _ _ = pure []

instance (EnemyRunner env) => RunMessage env AlmaHill where
  runMessage msg e@(AlmaHill attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId ->
      e <$ spawnAt (Just iid) eid (LocationWithTitle "Southside")
    UseCardAbility iid (EnemySource eid) _ 1 | eid == enemyId ->
      e <$ unshiftMessages
        (replicate 3 (InvestigatorDrawEncounterCard iid)
        <> [AddToVictory (toTarget attrs)]
        )
    _ -> AlmaHill <$> runMessage msg attrs

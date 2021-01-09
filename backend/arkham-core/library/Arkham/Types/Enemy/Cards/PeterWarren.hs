module Arkham.Types.Enemy.Cards.PeterWarren
  ( PeterWarren(..)
  , peterWarren
  )
where

import Arkham.Import

import Arkham.Types.Action hiding (Ability)
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Helpers
import Arkham.Types.Enemy.Runner

newtype PeterWarren = PeterWarren Attrs
  deriving newtype (Show, ToJSON, FromJSON)

peterWarren :: EnemyId -> PeterWarren
peterWarren uuid =
  PeterWarren
    $ baseAttrs uuid "01139"
    $ (healthDamageL .~ 1)
    . (fightL .~ 2)
    . (healthL .~ Static 3)
    . (evadeL .~ 3)
    . (uniqueL .~ True)

instance HasModifiersFor env PeterWarren where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env PeterWarren where
  getActions iid NonFast (PeterWarren attrs@Attrs {..}) =
    withBaseActions iid NonFast attrs $ do
      locationId <- getId @LocationId iid
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility
              (toSource attrs)
              1
              (ActionAbility (Just Parley) (Costs [ActionCost 1, ClueCost 2]))
            )
        | locationId == enemyLocation
        ]
  getActions _ _ _ = pure []

instance (EnemyRunner env) => RunMessage env PeterWarren where
  runMessage msg e@(PeterWarren attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId ->
      e <$ spawnAt (Just iid) eid (LocationWithTitle "Miskatonic University")
    UseCardAbility _ (EnemySource eid) _ 1 _ | eid == enemyId ->
      e <$ unshiftMessage (AddToVictory $ toTarget attrs)
    _ -> PeterWarren <$> runMessage msg attrs

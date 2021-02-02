module Arkham.Types.Enemy.Cards.ServantOfTheLurker where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner

newtype ServantOfTheLurker = ServantOfTheLurker Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

servantOfTheLurker :: EnemyId -> ServantOfTheLurker
servantOfTheLurker uuid =
  ServantOfTheLurker
    $ baseAttrs uuid "02104"
    $ (healthDamageL .~ 2)
    . (sanityDamageL .~ 2)
    . (fightL .~ 4)
    . (healthL .~ Static 5)
    . (evadeL .~ 2)
    . (preyL .~ LowestSkill SkillAgility)

instance HasModifiersFor env ServantOfTheLurker where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ServantOfTheLurker where
  getActions i window (ServantOfTheLurker attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env ServantOfTheLurker where
  runMessage msg (ServantOfTheLurker attrs@Attrs {..}) = case msg of
    PerformEnemyAttack iid eid | eid == enemyId -> do
      unshiftMessage $ DiscardTopOfDeck iid 2 Nothing
      ServantOfTheLurker <$> runMessage msg attrs
    _ -> ServantOfTheLurker <$> runMessage msg attrs

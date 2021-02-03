module Arkham.Types.Enemy.Cards.WizardOfYogSothoth
  ( WizardOfYogSothoth(..)
  , wizardOfYogSothoth
  )
where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.Trait

newtype WizardOfYogSothoth = WizardOfYogSothoth EnemyAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wizardOfYogSothoth :: EnemyId -> WizardOfYogSothoth
wizardOfYogSothoth uuid =
  WizardOfYogSothoth
    $ baseAttrs uuid "02087"
    $ (healthDamageL .~ 1)
    . (sanityDamageL .~ 2)
    . (fightL .~ 4)
    . (healthL .~ Static 3)
    . (evadeL .~ 3)
    . (preyL .~ FewestCards)

instance HasModifiersFor env WizardOfYogSothoth where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env WizardOfYogSothoth where
  getActions i window (WizardOfYogSothoth attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env WizardOfYogSothoth where
  runMessage msg e@(WizardOfYogSothoth attrs@EnemyAttrs {..}) = case msg of
    InvestigatorDrewEncounterCard iid card
      | iid `elem` enemyEngagedInvestigators -> e <$ when
        (any (`member` ecTraits card) [Hex, Pact])
        (unshiftMessage (EnemyAttack iid enemyId))
    InvestigatorDrewPlayerCard iid card -> e <$ when
      (any (`member` pcTraits card) [Hex, Pact])
      (unshiftMessage (EnemyAttack iid enemyId))
    _ -> WizardOfYogSothoth <$> runMessage msg attrs

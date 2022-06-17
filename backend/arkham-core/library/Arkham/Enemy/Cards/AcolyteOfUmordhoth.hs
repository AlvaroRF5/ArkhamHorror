module Arkham.Enemy.Cards.AcolyteOfUmordhoth where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Enemy.Runner
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher
import Arkham.Projection
import Arkham.Target

newtype AcolyteOfUmordhoth = AcolyteOfUmordhoth EnemyAttrs
  deriving anyclass IsEnemy
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

acolyteOfUmordhoth :: EnemyCard AcolyteOfUmordhoth
acolyteOfUmordhoth = enemyWith
  AcolyteOfUmordhoth
  Cards.acolyteOfUmordhoth
  (3, Static 3, 2)
  (1, 1)
  (preyL .~ Prey FewestCardsInHand)

instance HasModifiersFor AcolyteOfUmordhoth where
  getModifiersFor _ (EnemyTarget eid) (AcolyteOfUmordhoth a@EnemyAttrs {..})
    | eid == enemyId = do
      anyWithoutCards <- or <$> for
        (setToList enemyEngagedInvestigators)
        (fieldMap InvestigatorHand null)
      pure $ toModifiers a [ CannotBeEvaded | anyWithoutCards ]
  getModifiersFor _ _ _ = pure []

instance RunMessage AcolyteOfUmordhoth where
  runMessage msg (AcolyteOfUmordhoth attrs) =
    AcolyteOfUmordhoth <$> runMessage msg attrs

module Arkham.Act.Cards.WhatHaveYouDone where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Helpers
import Arkham.Act.Runner
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Cards
import Arkham.Matcher
import Arkham.Message hiding (EnemyDefeated)
import Arkham.Source
import Arkham.Timing qualified as Timing

newtype WhatHaveYouDone = WhatHaveYouDone ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

whatHaveYouDone :: ActCard WhatHaveYouDone
whatHaveYouDone = act (3, A) WhatHaveYouDone Cards.whatHaveYouDone Nothing

instance HasAbilities WhatHaveYouDone where
  getAbilities (WhatHaveYouDone x) =
    [ mkAbility x 1 $
        Objective $
          ForcedAbility $
            EnemyDefeated Timing.After Anyone ByAny $
              enemyIs Cards.ghoulPriest
    ]

instance RunMessage WhatHaveYouDone where
  runMessage msg a@(WhatHaveYouDone attrs) = case msg of
    UseCardAbility iid source 1 _ _
      | isSource attrs source ->
          a <$ push (AdvanceAct (toId attrs) (InvestigatorSource iid) AdvancedWithOther)
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs -> do
      lead <- getLead
      push $
        chooseOne
          lead
          [ Label
              "It was never much of a home. Burn it down! (→ _R1_)"
              [scenarioResolution 1]
          , Label
              "This \"hell-pit\" is my home! No way we are burning it! (→ _R2_)"
              [scenarioResolution 2]
          ]
      pure $ WhatHaveYouDone $ attrs & sequenceL .~ Sequence 3 B
    _ -> WhatHaveYouDone <$> runMessage msg attrs

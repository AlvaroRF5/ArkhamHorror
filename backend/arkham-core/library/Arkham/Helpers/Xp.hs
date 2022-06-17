module Arkham.Helpers.Xp where

import Arkham.Prelude

import Arkham.Card.CardDef
import Arkham.Classes.Query
import Arkham.Helpers.Query
import Arkham.Helpers.Modifiers
import Arkham.Helpers.Scenario
import Arkham.Id
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Location.Attrs ( Field (..) )
import Arkham.Matcher
import Arkham.Projection
import Arkham.Scenario.Attrs ( Field (..) )
import Arkham.Source
import Arkham.Target
import Data.Monoid ( Sum (..) )

getXp :: (Monad m, HasGame m) => m [(InvestigatorId, Int)]
getXp = getXpWithBonus 0

getXpWithBonus :: (Monad m, HasGame m) => Int -> m [(InvestigatorId, Int)]
getXpWithBonus bonus = do
  investigatorIds <- getInvestigatorIds
  for
    investigatorIds
    \iid -> do
      modifiers' <- getModifiers
        (InvestigatorSource iid)
        (InvestigatorTarget iid)
      victoryPileVictory <- mconcat <$> scenarioFieldMap
        ScenarioVictoryDisplay
        (map (Sum . fromMaybe 0 . cdVictoryPoints . toCardDef))
      locationVictory <-
        fmap mconcat
        . traverse
            (fieldMap LocationCardDef (Sum . fromMaybe 0 . cdVictoryPoints))
        =<< selectList (RevealedLocation <> LocationWithoutClues)
      let amount = getSum $ victoryPileVictory <> locationVictory
      pure (iid, foldl' applyModifier (amount + bonus) modifiers')
 where
  applyModifier n (XPModifier m) = max 0 (n + m)
  applyModifier n _ = n

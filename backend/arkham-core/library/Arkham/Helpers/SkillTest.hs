module Arkham.Helpers.SkillTest where

import Arkham.Prelude

import Arkham.Action
import Arkham.Card.CardDef
import Arkham.Classes.Entity
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Investigator
import Arkham.Id
import Arkham.Investigator.Types (Field(..))
import Arkham.Message (Message(BeginSkillTest))
import Arkham.Projection
import Arkham.SkillTest.Base
import Arkham.SkillTest.Type
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Arkham.Treachery.Types ( Field (..) )

getBaseValueForSkillTestType :: HasGame m => InvestigatorId -> Maybe Action -> SkillTestType -> m Int
getBaseValueForSkillTestType iid mAction = \case
  SkillSkillTest skillType -> baseSkillValueFor skillType mAction [] iid
  ResourceSkillTest -> field InvestigatorResources iid

getSkillTestInvestigator :: HasGame m => m (Maybe InvestigatorId)
getSkillTestInvestigator = fmap skillTestInvestigator <$> getSkillTest

getSkillTestTarget :: HasGame m => m (Maybe Target)
getSkillTestTarget = fmap skillTestTarget <$> getSkillTest

getSkillTestSource :: HasGame m => m (Maybe Source)
getSkillTestSource = fmap toSource <$> getSkillTest

getSkillTestAction :: HasGame m => m (Maybe Action)
getSkillTestAction = getSkillTestSource <&> \case
  Just (SkillTestSource _ _ _ maction) -> maction
  _ -> Nothing

getSkillTestSkillTypes :: HasGame m => m [SkillType]
getSkillTestSkillTypes = getSkillTestSource <&> \case
  Just (SkillTestSource _ (SkillSkillTest skillType) _ _) -> [skillType]
  _ -> []

getSkillTestMatchingSkillIcons :: HasGame m => m (Set SkillIcon)
getSkillTestMatchingSkillIcons = getSkillTestSource <&> \case
  Just (SkillTestSource _ stType _ _) -> case stType of
    SkillSkillTest skillType -> setFromList [#wild, SkillIcon skillType]
    ResourceSkillTest -> singleton #wild
  _ -> mempty

getIsBeingInvestigated :: HasGame m => LocationId -> m Bool
getIsBeingInvestigated lid = do
  mTarget <- getSkillTestTarget
  mAction <- getSkillTestAction
  pure $ mAction == Just Investigate && mTarget == Just (LocationTarget lid)

beginSkillTest :: InvestigatorId -> Source -> Target -> Maybe Action -> SkillType -> Int -> Message
beginSkillTest iid source target mAction sType n = BeginSkillTest iid source target mAction (SkillSkillTest sType) n

getIsScenarioAbility :: HasGame m => m Bool
getIsScenarioAbility = do
  source <- fromJustNote "damage outside skill test" <$> getSkillTestSource
  case source of
    SkillTestSource _ _ source' _ -> case source' of
      EnemySource _ -> pure True
      AgendaSource _ -> pure True
      LocationSource _ -> pure True
      TreacherySource tid ->
        -- If treachery has a subtype then it is a weakness not an encounter card
        isNothing . cdCardSubType <$> field TreacheryCardDef tid
      ActSource _ -> pure True
      _ -> pure False
    _ -> pure False


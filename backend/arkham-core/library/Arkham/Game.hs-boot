{-# OPTIONS_GHC -Wno-orphans #-}
module Arkham.Game where

import Arkham.Act.Attrs
import Arkham.Agenda.Attrs
import Arkham.Asset.Attrs
import Arkham.Classes.HasModifiersFor
import Arkham.Classes.HasTokenValue
import Arkham.Classes.HasRecord
import Arkham.Classes.Query
import Arkham.Distance
import Arkham.Effect.Attrs
import Arkham.Enemy.Attrs
import Arkham.Event.Attrs
import Arkham.History
import Arkham.Id
import Arkham.Investigator.Attrs
import Arkham.Location.Attrs
import Arkham.Matcher
import Arkham.Phase
import Arkham.Prelude
import Arkham.Projection
import Arkham.Scenario.Attrs
import Arkham.Skill.Attrs
import Arkham.SkillTest.Base
import Arkham.Treachery.Attrs
import Control.Monad.Random

data Game

class HasGameRef a where
  gameRefL :: Lens' a (IORef Game)

class HasGame m where
  getGame :: m Game

class HasStdGen a where
  genL :: Lens' a (IORef StdGen)

instance HasModifiersFor ()

instance Query AbilityMatcher
instance Query ActMatcher
instance Query AgendaMatcher
instance Query AssetMatcher
instance Query CardMatcher
instance Query CampaignMatcher
instance Query EffectMatcher
instance Query EnemyMatcher
instance Query EventMatcher
instance Query ExtendedCardMatcher
instance Query InvestigatorMatcher
instance Query LocationMatcher
instance Query PreyMatcher
instance Query RemainingActMatcher
instance Query ScenarioMatcher
instance Query SkillMatcher
instance Query TreacheryMatcher

instance Projection ActAttrs
instance Projection AgendaAttrs
instance Projection AssetAttrs
instance Projection EffectAttrs
instance Projection EnemyAttrs
instance Projection EventAttrs
instance Projection InvestigatorAttrs
instance Projection LocationAttrs
instance Projection ScenarioAttrs
instance Projection SkillAttrs
instance Projection TreacheryAttrs

instance HasTokenValue InvestigatorId
instance HasTokenValue ()

instance HasRecord ()

gamePhase :: Game -> Phase
gameSkillTest :: Game -> Maybe SkillTest
gamePhaseHistory :: Game -> HashMap InvestigatorId History
gameTurnHistory :: Game -> HashMap InvestigatorId History
gameRoundHistory :: Game -> HashMap InvestigatorId History

-- special
gameGetDistance :: Game -> LocationId -> LocationId -> Maybe Distance

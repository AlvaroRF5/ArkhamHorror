{-# LANGUAGE TemplateHaskell #-}

module Arkham.Target (
  module Arkham.Target,
) where

import Arkham.Prelude

import {-# SOURCE #-} Arkham.Ability.Types
import {-# SOURCE #-} Arkham.Card
import Arkham.Card.CardCode
import Arkham.Card.Id
import Arkham.ChaosToken
import Arkham.Id
import Arkham.Matcher
import Arkham.Phase
import Arkham.Tarot
import Arkham.Trait
import Control.Lens (Getting, Prism', prism')
import Data.Aeson.TH
import Data.Monoid (First)
import GHC.OverloadedLabels

data ForSkillTest = ForSkillTest

data Target
  = AssetTarget AssetId
  | EnemyTarget EnemyId
  | ScenarioTarget
  | EffectTarget EffectId
  | InvestigatorTarget InvestigatorId
  | InvestigatorHandTarget InvestigatorId -- used for cards in hand
  | InvestigatorDiscardTarget InvestigatorId -- used for cards in discard
  | LocationTarget LocationId
  | SetAsideLocationsTarget [Trait]
  | SkillTestTarget
  | AfterSkillTestTarget
  | TreacheryTarget TreacheryId
  | EncounterDeckTarget
  | ScenarioDeckTarget
  | AgendaDeckTarget
  | ActDeckTarget
  | AgendaTarget AgendaId
  | ActTarget ActId
  | CardIdTarget CardId
  | CardTarget Card
  | CardCodeTarget CardCode
  | SearchedCardTarget CardId
  | EventTarget EventId
  | SkillTarget SkillId
  | SkillTestInitiatorTarget Target
  | PhaseTarget Phase
  | ChaosTokenTarget ChaosToken
  | ChaosTokenFaceTarget ChaosTokenFace
  | TestTarget
  | ResourceTarget
  | YouTarget
  | InvestigationTarget InvestigatorId LocationId
  | ProxyTarget Target Target
  | StoryTarget StoryId
  | AgendaMatcherTarget AgendaMatcher
  | CampaignTarget
  | AbilityTarget InvestigatorId Ability
  | BothTarget Target Target
  | TarotTarget TarotCard
  deriving stock (Show, Eq, Ord, Data)

investigatorTarget :: Target -> Maybe InvestigatorId
investigatorTarget (InvestigatorTarget iid) = Just iid
investigatorTarget _ = Nothing

_InvestigatorTarget :: Prism' Target InvestigatorId
_InvestigatorTarget = prism' InvestigatorTarget investigatorTarget

instance IsLabel "investigator" (Getting (First InvestigatorId) Target InvestigatorId) where
  fromLabel = _InvestigatorTarget

pattern Initiator :: Target -> Target
pattern Initiator t <- SkillTestInitiatorTarget t
  where
    Initiator t = SkillTestInitiatorTarget t

pattern InitiatorProxy :: Target -> Target -> Target
pattern InitiatorProxy t a <- SkillTestInitiatorTarget (ProxyTarget t a)
  where
    InitiatorProxy t a = SkillTestInitiatorTarget (ProxyTarget t a)

class Targetable a where
  toTarget :: a -> Target
  isTarget :: a -> Target -> Bool
  isTarget = (==) . toTarget

instance Targetable Target where
  toTarget = id

instance Targetable ActId where
  toTarget = ActTarget

instance Targetable AgendaId where
  toTarget = AgendaTarget

instance Targetable CardId where
  toTarget = CardIdTarget

instance Targetable LocationId where
  toTarget = LocationTarget

instance Targetable EnemyId where
  toTarget = EnemyTarget

instance Targetable TreacheryId where
  toTarget = TreacheryTarget

instance Targetable InvestigatorId where
  toTarget = InvestigatorTarget

instance Targetable AssetId where
  toTarget = AssetTarget

instance Targetable EventId where
  toTarget = EventTarget

instance Targetable SkillId where
  toTarget = SkillTarget

instance Targetable StoryId where
  toTarget = StoryTarget

toActionTarget :: Target -> Target
toActionTarget (ProxyTarget _ actionTarget) = actionTarget
toActionTarget target = target

toProxyTarget :: Target -> Target
toProxyTarget (ProxyTarget proxyTarget _) = proxyTarget
toProxyTarget target = target

_EnemyTarget :: Traversal' Target EnemyId
_EnemyTarget f (EnemyTarget enemy) = EnemyTarget <$> f enemy
_EnemyTarget _ other = pure other

$(deriveJSON defaultOptions ''Target)

instance FromJSONKey Target
instance ToJSONKey Target

module Arkham.Matcher (
  module Arkham.Matcher,
  module Arkham.Matcher.Patterns,
  module Arkham.Matcher.Types,
) where

import Arkham.Prelude

import Arkham.Campaigns.TheForgottenAge.Supply
import Arkham.Card.CardCode
import Arkham.Id
import Arkham.Matcher.Patterns
import Arkham.Matcher.Types
import Arkham.Modifier
import Arkham.Trait (Trait)
import Control.Lens (over, transform)
import Data.Data.Lens (biplate)

class Locatable a where
  at_ :: LocationMatcher -> a

instance Locatable InvestigatorMatcher where
  at_ = InvestigatorAt

instance Locatable EnemyMatcher where
  at_ = EnemyAt

instance Locatable AssetMatcher where
  at_ = AssetAt

class IsMatcher matcher => Has matcher a where
  has :: a -> matcher

have :: Has matcher a => a -> matcher
have = has

instance Has InvestigatorMatcher Supply where
  has = InvestigatorWithSupply

affectsOthers :: InvestigatorMatcher -> InvestigatorMatcher
affectsOthers You = You
affectsOthers NotYou =
  InvestigatorIfThen
    (InvestigatorWithModifier CannotAffectOtherPlayersWithPlayerEffectsExceptDamage)
    NoOne
    NotYou
affectsOthers matcher =
  InvestigatorIfThen
    (InvestigatorWithModifier CannotAffectOtherPlayersWithPlayerEffectsExceptDamage)
    (You <> matcher)
    matcher

class OneOf a where
  oneOf :: [a] -> a

instance OneOf ActionMatcher where
  oneOf = ActionOneOf

instance OneOf ChaosTokenMatcher where
  oneOf = ChaosTokenMatchesAny

instance OneOf ExtendedCardMatcher where
  oneOf = ExtendedCardWithOneOf

instance OneOf CardMatcher where
  oneOf = CardWithOneOf

instance OneOf WindowMatcher where
  oneOf = OrWindowMatcher

instance OneOf InvestigatorMatcher where
  oneOf = AnyInvestigator

instance OneOf LocationMatcher where
  oneOf = LocationMatchAny

instance OneOf EnemyMatcher where
  oneOf = EnemyOneOf

instance OneOf EventMatcher where
  oneOf = EventOneOf

instance OneOf AssetMatcher where
  oneOf = AssetOneOf

instance OneOf TreacheryMatcher where
  oneOf = TreacheryOneOf

class WithTrait a where
  withTrait :: Trait -> a

hasAnyTrait :: (OneOf a, WithTrait a) => [Trait] -> a
hasAnyTrait traits = oneOf (withTrait <$> traits)

instance WithTrait AssetMatcher where
  withTrait = AssetWithTrait
  {-# INLINE withTrait #-}

instance WithTrait EnemyMatcher where
  withTrait = EnemyWithTrait
  {-# INLINE withTrait #-}

instance WithTrait CardMatcher where
  withTrait = CardWithTrait
  {-# INLINE withTrait #-}

instance WithTrait LocationMatcher where
  withTrait = LocationWithTrait
  {-# INLINE withTrait #-}

-- ** Investigator Helpers **

investigatorIs :: HasCardCode a => a -> InvestigatorMatcher
investigatorIs = InvestigatorIs . toCardCode

notInvestigator :: InvestigatorId -> InvestigatorMatcher
notInvestigator = NotInvestigator . InvestigatorWithId

colocatedWith :: InvestigatorId -> InvestigatorMatcher
colocatedWith = InvestigatorAt . LocationWithInvestigator . InvestigatorWithId

investigatorEngagedWith :: (AsId enemy, IdOf enemy ~ EnemyId) => enemy -> InvestigatorMatcher
investigatorEngagedWith = InvestigatorEngagedWith . EnemyWithId . asId

investigatorAt :: LocationId -> InvestigatorMatcher
investigatorAt = InvestigatorAt . LocationWithId

replaceYouMatcher :: Data a => InvestigatorId -> a -> a
replaceYouMatcher iid = replaceInvestigatorMatcher (transform replace)
 where
  replace You = InvestigatorWithId iid
  replace NotYou = NotInvestigator (InvestigatorWithId iid)
  replace m = m

replaceThatInvestigator :: Data a => InvestigatorId -> a -> a
replaceThatInvestigator iid = replaceInvestigatorMatcher (transform replace)
 where
  replace ThatInvestigator = InvestigatorWithId iid
  replace m = m

replaceInvestigatorMatcher :: Data a => (InvestigatorMatcher -> InvestigatorMatcher) -> a -> a
replaceInvestigatorMatcher = over biplate

handWith :: HasCardCode a => a -> InvestigatorMatcher
handWith = HandWith . hasCard
{-# INLINE handWith #-}

noModifier :: ModifierType -> InvestigatorMatcher
noModifier = InvestigatorWithoutModifier
{-# INLINE noModifier #-}

-- ** Prey Helpers **

-- NOTE: OnlyPrey and Bearer of used to not combine, but we need to do this for
-- correct engagement checking. Otherwise if an enemy with that prey was
-- supposed to spawn at a different location, it could not since this matcher
-- would always return that prey
preyWith :: PreyMatcher -> InvestigatorMatcher -> PreyMatcher
preyWith (Prey m1) m2 = Prey $ m1 <> m2
preyWith (OnlyPrey m1) m2 = OnlyPrey $ m1 <> m2
preyWith (BearerOf e) m = RestrictedBearerOf e m
preyWith (RestrictedBearerOf e m1) m2 = RestrictedBearerOf e $ m1 <> m2

-- ** Asset Helpers **

assetIs :: HasCardCode a => a -> AssetMatcher
assetIs = AssetIs . toCardCode

assetControlledBy :: InvestigatorId -> AssetMatcher
assetControlledBy = AssetControlledBy . InvestigatorWithId

assetAt :: LocationId -> AssetMatcher
assetAt = AssetAt . LocationWithId

assetAtLocationWith :: InvestigatorId -> AssetMatcher
assetAtLocationWith = AssetAt . locationWithInvestigator

-- ** Enemy Helpers **

enemyIs :: HasCardCode a => a -> EnemyMatcher
enemyIs = EnemyIs . toCardCode

enemyAt :: LocationId -> EnemyMatcher
enemyAt = EnemyAt . LocationWithId

enemyAtLocationWith :: InvestigatorId -> EnemyMatcher
enemyAtLocationWith = EnemyAt . locationWithInvestigator

enemyEngagedWith :: InvestigatorId -> EnemyMatcher
enemyEngagedWith = EnemyIsEngagedWith . InvestigatorWithId

-- ** Effect Helpers **

effectFrom :: HasCardCode a => a -> EffectMatcher
effectFrom = EffectWithCardCode . toCardCode

-- ** Location Helpers **

canEnterLocation :: (AsId a, IdOf a ~ InvestigatorId) => a -> LocationMatcher
canEnterLocation = CanEnterLocation . InvestigatorWithId . asId
{-# INLINE canEnterLocation #-}

locationIs :: HasCardCode a => a -> LocationMatcher
locationIs = LocationIs . toCardCode
{-# INLINE locationIs #-}

locationWithAsset :: (AsId a, IdOf a ~ AssetId) => a -> LocationMatcher
locationWithAsset = LocationWithAsset . AssetWithId . asId
{-# INLINE locationWithAsset #-}

locationWithEnemy :: (AsId a, IdOf a ~ EnemyId) => a -> LocationMatcher
locationWithEnemy = LocationWithEnemy . EnemyWithId . asId
{-# INLINE locationWithEnemy #-}

locationWithInvestigator :: InvestigatorId -> LocationMatcher
locationWithInvestigator = LocationWithInvestigator . InvestigatorWithId
{-# INLINE locationWithInvestigator #-}

locationWithDiscoverableCluesBy :: InvestigatorId -> LocationMatcher
locationWithDiscoverableCluesBy =
  LocationWithDiscoverableCluesBy . InvestigatorWithId
{-# INLINE locationWithDiscoverableCluesBy #-}

locationWithTreachery :: (AsId a, IdOf a ~ TreacheryId) => a -> LocationMatcher
locationWithTreachery = LocationWithTreachery . TreacheryWithId . asId
{-# INLINE locationWithTreachery #-}

locationWithoutTreachery :: HasCardCode a => a -> LocationMatcher
locationWithoutTreachery = LocationWithoutTreachery . treacheryIs
{-# INLINE locationWithoutTreachery #-}

accessibleFrom :: (AsId a, IdOf a ~ LocationId) => a -> LocationMatcher
accessibleFrom = AccessibleFrom . LocationWithId . asId
{-# INLINE accessibleFrom #-}

accessibleTo :: (AsId a, IdOf a ~ LocationId) => a -> LocationMatcher
accessibleTo = AccessibleTo . LocationWithId . asId
{-# INLINE accessibleTo #-}

locationNotOneOf :: IsLocationMatcher a => [a] -> LocationMatcher
locationNotOneOf = LocationNotOneOf . map toLocationMatcher
{-# INLINE locationNotOneOf #-}

-- ** Treachery Helpers **

treacheryIs :: HasCardCode a => a -> TreacheryMatcher
treacheryIs = TreacheryIs . toCardCode

treacheryAt :: LocationId -> TreacheryMatcher
treacheryAt = TreacheryAt . LocationWithId
{-# INLINE treacheryAt #-}

treacheryInHandOf :: InvestigatorId -> TreacheryMatcher
treacheryInHandOf = TreacheryInHandOf . InvestigatorWithId

treacheryInThreatAreaOf :: InvestigatorId -> TreacheryMatcher
treacheryInThreatAreaOf = TreacheryInThreatAreaOf . InvestigatorWithId

-- ** Event Helpers **

eventIs :: HasCardCode a => a -> EventMatcher
eventIs = EventIs . toCardCode

eventAt :: LocationId -> EventMatcher
eventAt = EventAt . LocationWithId

eventControlledBy :: InvestigatorId -> EventMatcher
eventControlledBy = EventControlledBy . InvestigatorWithId

-- ** Skill Helpers **

skillIs :: HasCardCode a => a -> SkillMatcher
skillIs = SkillIs . toCardCode

skillControlledBy :: InvestigatorId -> SkillMatcher
skillControlledBy = SkillControlledBy . InvestigatorWithId

-- ** Story Helpers **

storyIs :: HasCardCode a => a -> StoryMatcher
storyIs = StoryIs . toCardCode

-- ** Card Helpers **

cardIs :: HasCardCode a => a -> CardMatcher
cardIs = CardWithCardCode . toCardCode

-- ** Extended Card Helpers **

inHandOf :: InvestigatorId -> ExtendedCardMatcher
inHandOf = InHandOf . InvestigatorWithId

inDiscardOf :: InvestigatorId -> ExtendedCardMatcher
inDiscardOf = InDiscardOf . InvestigatorWithId

basic :: CardMatcher -> ExtendedCardMatcher
basic = BasicCardMatch

-- ** Card List Helpers **

hasCard :: HasCardCode a => a -> CardListMatcher
hasCard = HasCard . cardIs

-- ** Replacements

replaceLocationMatcher :: Data a => LocationId -> LocationMatcher -> a -> a
replaceLocationMatcher lid m = over biplate (transform go)
 where
  go n | m == n = LocationWithId lid
  go x = x

replaceThatLocation :: Data a => LocationId -> a -> a
replaceThatLocation lid = replaceLocationMatcher lid ThatLocation

defaultRemoveDoomMatchers :: RemoveDoomMatchers
defaultRemoveDoomMatchers =
  RemoveDoomMatchers
    { removeDoomLocations = Anywhere
    , removeDoomInvestigators = Anyone
    , removeDoomEnemies = AnyEnemy
    , removeDoomAssets = AnyAsset
    , removeDoomActs = AnyAct
    , removeDoomAgendas = AnyAgenda
    , removeDoomTreacheries = AnyTreachery
    , removeDoomEvents = AnyEvent
    , removeDoomSkills = AnySkill
    }

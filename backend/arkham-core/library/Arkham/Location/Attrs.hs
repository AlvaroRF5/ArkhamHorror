{-# OPTIONS_GHC -Wno-orphans #-}
module Arkham.Location.Attrs
  ( module Arkham.Location.Attrs
  , module X
  , Field(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Card
import Arkham.Classes.Entity
import Arkham.Classes.HasAbilities
import Arkham.Classes.HasModifiersFor
import Arkham.Classes.RunMessage.Internal
import Arkham.Cost
import Arkham.Criteria
import Arkham.Direction
import Arkham.Field
import Arkham.GameValue
import Arkham.Id
import Arkham.Keyword
import Arkham.Label qualified as L
import Arkham.Location.Base as X
import Arkham.Location.Cards
import Arkham.LocationSymbol
import Arkham.Matcher ( LocationMatcher (..) )
import Arkham.Name
import Arkham.Source
import Arkham.Target
import Arkham.Trait ( Trait )
import Data.Typeable

class
  ( Typeable a
  , ToJSON a
  , FromJSON a
  , Eq a
  , Show a
  , HasAbilities a
  , HasModifiersFor a
  , RunMessage a
  , Entity a
  , EntityId a ~ LocationId
  , EntityAttrs a ~ LocationAttrs
  ) => IsLocation a where
    toLocation :: a -> Location
    toLocation = Location

type LocationCard a = CardBuilder LocationId a

data instance Field LocationAttrs :: Type -> Type where
  LocationClues :: Field LocationAttrs Int
  LocationResources :: Field LocationAttrs Int
  LocationHorror :: Field LocationAttrs Int
  LocationDoom :: Field LocationAttrs Int
  LocationShroud :: Field LocationAttrs Int
  LocationTraits :: Field LocationAttrs (HashSet Trait)
  LocationKeywords :: Field LocationAttrs (HashSet Keyword)
  LocationUnrevealedName :: Field LocationAttrs Name
  LocationName :: Field LocationAttrs Name
  LocationConnectedMatchers :: Field LocationAttrs [LocationMatcher]
  LocationRevealedConnectedMatchers :: Field LocationAttrs [LocationMatcher]
  LocationRevealed :: Field LocationAttrs Bool
  LocationConnectsTo :: Field LocationAttrs (HashSet Direction)
  LocationCardsUnderneath :: Field LocationAttrs [Card]
  LocationConnectedLocations :: Field LocationAttrs (HashSet LocationId)
  LocationInvestigators :: Field LocationAttrs (HashSet InvestigatorId)
  LocationEnemies :: Field LocationAttrs (HashSet EnemyId)
  LocationAssets :: Field LocationAttrs (HashSet AssetId)
  LocationEvents :: Field LocationAttrs (HashSet EventId)
  LocationTreacheries :: Field LocationAttrs (HashSet TreacheryId)
  -- virtual
  LocationCardDef :: Field LocationAttrs CardDef
  LocationCard :: Field LocationAttrs Card
  LocationAbilities :: Field LocationAttrs [Ability]

symbolL :: Lens' LocationAttrs LocationSymbol
symbolL = lens locationSymbol $ \m x -> m { locationSymbol = x }

canBeFlippedL :: Lens' LocationAttrs Bool
canBeFlippedL =
  lens locationCanBeFlipped $ \m x -> m { locationCanBeFlipped = x }

costToEnterUnrevealedL :: Lens' LocationAttrs Cost
costToEnterUnrevealedL = lens locationCostToEnterUnrevealed
  $ \m x -> m { locationCostToEnterUnrevealed = x }

connectsToL :: Lens' LocationAttrs (HashSet Direction)
connectsToL = lens locationConnectsTo $ \m x -> m { locationConnectsTo = x }

connectedMatchersL :: Lens' LocationAttrs [LocationMatcher]
connectedMatchersL =
  lens locationConnectedMatchers $ \m x -> m { locationConnectedMatchers = x }

revealedConnectedMatchersL :: Lens' LocationAttrs [LocationMatcher]
revealedConnectedMatchersL = lens locationRevealedConnectedMatchers
  $ \m x -> m { locationRevealedConnectedMatchers = x }

revealedSymbolL :: Lens' LocationAttrs LocationSymbol
revealedSymbolL =
  lens locationRevealedSymbol $ \m x -> m { locationRevealedSymbol = x }

labelL :: Lens' LocationAttrs Text
labelL = lens locationLabel $ \m x -> m { locationLabel = x }

treacheriesL :: Lens' LocationAttrs (HashSet TreacheryId)
treacheriesL = lens locationTreacheries $ \m x -> m { locationTreacheries = x }

eventsL :: Lens' LocationAttrs (HashSet EventId)
eventsL = lens locationEvents $ \m x -> m { locationEvents = x }

investigatorsL :: Lens' LocationAttrs (HashSet InvestigatorId)
investigatorsL =
  lens locationInvestigators $ \m x -> m { locationInvestigators = x }

enemiesL :: Lens' LocationAttrs (HashSet EnemyId)
enemiesL = lens locationEnemies $ \m x -> m { locationEnemies = x }

assetsL :: Lens' LocationAttrs (HashSet AssetId)
assetsL = lens locationAssets $ \m x -> m { locationAssets = x }

doomL :: Lens' LocationAttrs Int
doomL = lens locationDoom $ \m x -> m { locationDoom = x }

horrorL :: Lens' LocationAttrs Int
horrorL = lens locationHorror $ \m x -> m { locationHorror = x }

cluesL :: Lens' LocationAttrs Int
cluesL = lens locationClues $ \m x -> m { locationClues = x }

resourcesL :: Lens' LocationAttrs Int
resourcesL = lens locationResources $ \m x -> m { locationResources = x }

revealedL :: Lens' LocationAttrs Bool
revealedL = lens locationRevealed $ \m x -> m { locationRevealed = x }

directionsL :: Lens' LocationAttrs (HashMap Direction LocationId)
directionsL = lens locationDirections $ \m x -> m { locationDirections = x }

cardsUnderneathL :: Lens' LocationAttrs [Card]
cardsUnderneathL =
  lens locationCardsUnderneath $ \m x -> m { locationCardsUnderneath = x }

instance Entity LocationAttrs where
  type EntityId LocationAttrs = LocationId
  type EntityAttrs LocationAttrs = LocationAttrs
  toId = locationId
  toAttrs = id
  overAttrs f = f

instance TargetEntity LocationAttrs where
  toTarget = LocationTarget . toId
  isTarget LocationAttrs { locationId } (LocationTarget lid) =
    locationId == lid
  isTarget attrs (SkillTestInitiatorTarget target) = isTarget attrs target
  isTarget _ _ = False

instance SourceEntity LocationAttrs where
  toSource = LocationSource . toId
  isSource LocationAttrs { locationId } (LocationSource lid) =
    locationId == lid
  isSource LocationAttrs { locationId } (ProxySource (LocationSource lid) _) =
    locationId == lid
  isSource _ _ = False


instance HasCardCode LocationAttrs where
  toCardCode = locationCardCode

instance HasCardDef LocationAttrs where
  toCardDef a = case lookup (locationCardCode a) allLocationCards of
    Just def -> def
    Nothing ->
      error $ "missing card def for location " <> show (locationCardCode a)

unrevealed :: LocationAttrs -> Bool
unrevealed = not . locationRevealed

revealed :: LocationAttrs -> Bool
revealed = locationRevealed

location
  :: (LocationAttrs -> a)
  -> CardDef
  -> Int
  -> GameValue Int
  -> LocationSymbol
  -> [LocationSymbol]
  -> CardBuilder LocationId a
location f def shroud' revealClues symbol' connectedSymbols' =
  locationWith f def shroud' revealClues symbol' connectedSymbols' id

locationWithRevealedSideConnections
  :: (LocationAttrs -> a)
  -> CardDef
  -> Int
  -> GameValue Int
  -> LocationSymbol
  -> [LocationSymbol]
  -> LocationSymbol
  -> [LocationSymbol]
  -> CardBuilder LocationId a
locationWithRevealedSideConnections f def shroud' revealClues symbol' connectedSymbols' revealedSymbol' revealedConnectedSymbols'
  = locationWithRevealedSideConnectionsWith
    f
    def
    shroud'
    revealClues
    symbol'
    connectedSymbols'
    revealedSymbol'
    revealedConnectedSymbols'
    id

locationWithRevealedSideConnectionsWith
  :: (LocationAttrs -> a)
  -> CardDef
  -> Int
  -> GameValue Int
  -> LocationSymbol
  -> [LocationSymbol]
  -> LocationSymbol
  -> [LocationSymbol]
  -> (LocationAttrs -> LocationAttrs)
  -> CardBuilder LocationId a
locationWithRevealedSideConnectionsWith f def shroud' revealClues symbol' connectedSymbols' revealedSymbol' revealedConnectedSymbols' g
  = locationWith
    f
    def
    shroud'
    revealClues
    symbol'
    connectedSymbols'
    (g
    . (revealedConnectedMatchersL
      <>~ map LocationWithSymbol revealedConnectedSymbols'
      )
    . (revealedSymbolL .~ revealedSymbol')
    )

locationWith
  :: (LocationAttrs -> a)
  -> CardDef
  -> Int
  -> GameValue Int
  -> LocationSymbol
  -> [LocationSymbol]
  -> (LocationAttrs -> LocationAttrs)
  -> CardBuilder LocationId a
locationWith f def shroud' revealClues symbol' connectedSymbols' g =
  CardBuilder
    { cbCardCode = cdCardCode def
    , cbCardBuilder = \lid -> f . g $ LocationAttrs
      { locationId = lid
      , locationCardCode = toCardCode def
      , locationLabel = nameToLabel (cdName def)
      , locationRevealClues = revealClues
      , locationClues = 0
      , locationHorror = 0
      , locationDoom = 0
      , locationResources = 0
      , locationShroud = shroud'
      , locationRevealed = not (cdDoubleSided def)
      , locationInvestigators = mempty
      , locationEnemies = mempty
      , locationSymbol = symbol'
      , locationRevealedSymbol = symbol'
      , locationConnectedMatchers = map LocationWithSymbol connectedSymbols'
      , locationRevealedConnectedMatchers = map
        LocationWithSymbol
        connectedSymbols'
      , locationTreacheries = mempty
      , locationEvents = mempty
      , locationAssets = mempty
      , locationDirections = mempty
      , locationConnectsTo = mempty
      , locationCardsUnderneath = mempty
      , locationCostToEnterUnrevealed = ActionCost 1
      , locationCanBeFlipped = False
      }
    }

locationResignAction :: LocationAttrs -> Ability
locationResignAction attrs = toLocationAbility
  attrs
  (mkAbility attrs 99 $ ActionAbility (Just Action.Resign) (ActionCost 1))

toLocationAbility :: LocationAttrs -> Ability -> Ability
toLocationAbility attrs ability = ability
  { abilityCriteria = Just
    (fromMaybe mempty (abilityCriteria ability)
    <> OnLocation (LocationWithId $ toId attrs)
    )
  }

locationAbility :: Ability -> Ability
locationAbility ability = case abilitySource ability of
  LocationSource lid -> ability
    { abilityCriteria = Just
      (fromMaybe mempty (abilityCriteria ability)
      <> OnLocation (LocationWithId lid)
      )
    }
  _ -> ability

on :: InvestigatorId -> LocationAttrs -> Bool
on iid LocationAttrs { locationInvestigators } =
  iid `member` locationInvestigators

data Location = forall a . IsLocation a => Location a

instance Eq Location where
  (Location (a :: a)) == (Location (b :: b)) = case eqT @a @b of
    Just Refl -> a == b
    Nothing -> False

instance Show Location where
  show (Location a) = show a

instance ToJSON Location where
  toJSON (Location a) = toJSON a

toLocationSymbol :: Location -> LocationSymbol
toLocationSymbol = locationSymbol . toAttrs

toLocationLabel :: Location -> L.Label
toLocationLabel = L.Label . locationLabel . toAttrs

instance HasCardCode Location where
  toCardCode = toCardCode . toAttrs

instance HasAbilities Location where
  getAbilities (Location a) = getAbilities a

instance HasModifiersFor Location where
  getModifiersFor source target (Location a) = getModifiersFor source target a

instance Entity Location where
  type EntityId Location = LocationId
  type EntityAttrs Location = LocationAttrs
  toId = toId . toAttrs
  toAttrs (Location l) = toAttrs l
  overAttrs f (Location a) = Location $ overAttrs f a

instance Named Location where
  toName = toName . toAttrs

instance Named (Unrevealed Location) where
  toName (Unrevealed l) = toName . Unrevealed $ toAttrs l

instance TargetEntity Location where
  toTarget = toTarget . toAttrs
  isTarget = isTarget . toAttrs

instance SourceEntity Location where
  toSource = toSource . toAttrs
  isSource = isSource . toAttrs

isEmptyLocation :: Location -> Bool
isEmptyLocation =
  and . sequence [noInvestigatorsAtLocation, noEnemiesAtLocation]

noInvestigatorsAtLocation :: Location -> Bool
noInvestigatorsAtLocation l = null investigators'
  where investigators' = locationInvestigators $ toAttrs l

noEnemiesAtLocation :: Location -> Bool
noEnemiesAtLocation l = null enemies'
  where enemies' = locationEnemies $ toAttrs l

isRevealed :: Location -> Bool
isRevealed = locationRevealed . toAttrs

data SomeLocationCard = forall a . IsLocation a => SomeLocationCard
  (LocationCard a)

someLocationCardCode :: SomeLocationCard -> CardCode
someLocationCardCode (SomeLocationCard a) = cbCardCode a

instance Named LocationAttrs where
  toName l = if locationRevealed l
    then fromMaybe baseName (cdRevealedName $ toCardDef l)
    else baseName
    where baseName = toName (toCardDef l)

instance Named (Unrevealed LocationAttrs) where
  toName (Unrevealed l) = toName (toCardDef l)

instance IsCard LocationAttrs where
  toCardId = unLocationId . locationId
  toCardOwner = const Nothing

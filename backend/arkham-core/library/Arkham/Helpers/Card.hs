module Arkham.Helpers.Card (
  module Arkham.Helpers.Card,
  module Arkham.Helpers.Campaign,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.ActiveCost.Base
import Arkham.Asset.Types
import Arkham.Card
import Arkham.Classes.Entity
import Arkham.Classes.HasAbilities
import Arkham.Classes.HasGame
import Arkham.Classes.Query
import Arkham.Enemy.Types
import {-# SOURCE #-} Arkham.Entities
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Campaign
import Arkham.Helpers.Modifiers
import Arkham.Id
import Arkham.Location.Types
import Arkham.Matcher hiding (AssetCard, LocationCard)
import Arkham.Projection
import Arkham.SkillType
import Arkham.Target

isDiscardable :: Card -> Bool
isDiscardable = not . isWeakness
 where
  isWeakness = \case
    PlayerCard pc -> isJust $ cdCardSubType $ toCardDef pc
    EncounterCard _ -> True -- maybe?
    VengeanceCard _ -> False -- should be an error

getCardPayments :: HasGame m => Card -> m (Maybe Payment)
getCardPayments c = do
  costs <- getActiveCosts
  pure $ activeCostPayments <$> find (isCardTarget . activeCostTarget) costs
 where
  isCardTarget = \case
    ForAbility {} -> False
    ForAdditionalCost {} -> False
    ForCard _ c' -> toCardId c == toCardId c'
    ForCost c' -> toCardId c == toCardId c'

extendedCardMatch
  :: (HasGame m, IsCard c) => c -> ExtendedCardMatcher -> m Bool
extendedCardMatch (toCard -> c) matcher =
  selectAny (BasicCardMatch (CardWithId (toCardId c)) <> matcher)

class ConvertToCard a where
  convertToCard :: HasGame m => a -> m Card

instance ConvertToCard EnemyId where
  convertToCard = getEntityCard @Enemy

instance ConvertToCard AssetId where
  convertToCard = getEntityCard @Asset

instance ConvertToCard LocationId where
  convertToCard = getEntityCard @Location

instance ConvertToCard Card where
  convertToCard = pure

instance ConvertToCard CardId where
  convertToCard = getCard

class (Projection a, Entity a) => CardEntity a where
  cardField :: Field a Card

getEntityCard
  :: forall a m. (CardEntity a, HasGame m) => EntityId a -> m Card
getEntityCard = field (cardField @a)

instance CardEntity Enemy where
  cardField = EnemyCard

instance CardEntity Asset where
  cardField = AssetCard

instance CardEntity Location where
  cardField = LocationCard

getCardField :: (ConvertToCard c, HasGame m) => (CardDef -> a) -> c -> m a
getCardField f c = f . toCardDef <$> convertToCard c

getVictoryPoints :: (ConvertToCard c, HasGame m) => c -> m (Maybe Int)
getVictoryPoints c = do
  card <- convertToCard c
  printedVictory <- getPrintedVictoryPoints card
  modifiers' <- getModifiers $ toCardId card
  if LoseVictory `elem` modifiers'
    then pure Nothing
    else pure $ foldr applyModifier printedVictory modifiers'
 where
  applyModifier (GainVictory n) _ = Just n
  applyModifier _ n = n

getHasVictoryPoints :: (ConvertToCard c, HasGame m) => c -> m Bool
getHasVictoryPoints c = isJust <$> getVictoryPoints c

getPrintedVictoryPoints :: (ConvertToCard c, HasGame m) => c -> m (Maybe Int)
getPrintedVictoryPoints = getCardField cdVictoryPoints

-- To get abilities we convert to some entity in Entities and get all abilities
getCardAbilities :: InvestigatorId -> Card -> [Ability]
getCardAbilities iid c = getAbilities $ addCardEntityWith iid id mempty c

findJustCard :: HasGame m => (Card -> Bool) -> m Card
findJustCard cardPred = fromJustNote "invalid card" <$> findCard cardPred

findUniqueCard :: HasGame m => CardDef -> m Card
findUniqueCard def = findJustCard (`cardMatch` (cardIs def <> CardIsUnique))

iconsForCard :: HasGame m => Card -> m [SkillIcon]
iconsForCard c@(PlayerCard MkPlayerCard {..}) = do
  modifiers' <- getModifiers (CardIdTarget pcId)
  pure
    $ foldr
      applyAfterSkillModifiers
      (foldr applySkillModifiers (cdSkills $ toCardDef c) modifiers')
      modifiers'
 where
  applySkillModifiers (AddSkillIcons xs) ys = xs <> ys
  applySkillModifiers (RemoveSkillIcons xs) ys = ys \\ xs
  applySkillModifiers _ ys = ys
  applyAfterSkillModifiers DoubleSkillIcons ys = ys <> ys
  applyAfterSkillModifiers _ ys = ys
iconsForCard _ = pure []

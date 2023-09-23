module Arkham.Investigator.Cards.GavriellaMizrah (
  gavriellaMizrah,
  GavriellaMizrah (..),
) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards hiding (gavriellaMizrah)
import Arkham.Card
import Arkham.Discover
import Arkham.Event.Cards qualified as Cards
import Arkham.Helpers.Modifiers
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Matcher
import Arkham.Treachery.Cards qualified as Cards

newtype GavriellaMizrah = GavriellaMizrah (InvestigatorAttrs `With` PrologueMetadata)
  deriving stock (Show, Eq, Generic)
  deriving anyclass (IsInvestigator, ToJSON, FromJSON)
  deriving newtype (Entity)

gavriellaMizrah :: PrologueMetadata -> InvestigatorCard GavriellaMizrah
gavriellaMizrah meta =
  startsWith [Cards.fortyFiveAutomatic, Cards.physicalTraining, Cards.fateOfAllFools]
    $ startsWithInHand
      [ Cards.firstAid
      , Cards.guardDog
      , Cards.evidence
      , Cards.dodge
      , Cards.extraAmmunition1
      , Cards.delayTheInevitable
      , Cards.delayTheInevitable
      ]
    $ investigator (GavriellaMizrah . (`with` meta)) Cards.gavriellaMizrah
    $ Stats {health = 8, sanity = 4, willpower = 3, intellect = 2, combat = 4, agility = 1}

instance HasModifiersFor GavriellaMizrah where
  getModifiersFor target (GavriellaMizrah (a `With` _)) | a `isTarget` target = do
    pure
      $ toModifiersWith a setActiveDuringSetup
      $ [CannotTakeAction #draw, CannotDrawCards, CannotManipulateDeck, StartingResources (-4)]
  getModifiersFor (AssetTarget aid) (GavriellaMizrah (a `With` _)) = do
    isFortyFiveAutomatic <- aid <=~> assetIs Cards.fortyFiveAutomatic
    pure $ toModifiersWith a setActiveDuringSetup [AdditionalStartingUses (-2) | isFortyFiveAutomatic]
  getModifiersFor _ _ = pure []

instance HasAbilities GavriellaMizrah where
  getAbilities (GavriellaMizrah (a `With` _)) =
    [ restrictedAbility a 1 (Self <> ClueOnLocation)
        $ freeReaction (EnemyAttacksEvenIfCancelled #after You AnyEnemyAttack AnyEnemy)
    ]

instance HasChaosTokenValue GavriellaMizrah where
  getChaosTokenValue iid ElderSign (GavriellaMizrah (attrs `With` _)) | attrs `is` iid = do
    pure $ ChaosTokenValue ElderSign $ PositiveModifier 1
  getChaosTokenValue _ token _ = pure $ ChaosTokenValue token mempty

instance RunMessage GavriellaMizrah where
  runMessage msg i@(GavriellaMizrah (attrs `With` meta)) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      pushMessage $ discoverAtYourLocation iid (toAbilitySource attrs 1) 1
      pure i
    ResolveChaosToken _ ElderSign iid | attrs `is` iid -> do
      pushAll
        [HealHorror (toTarget attrs) (toSource attrs) 1, HealDamage (toTarget attrs) (toSource attrs) 1]
      pure i
    DrawStartingHand iid | attrs `is` iid -> pure i
    InvestigatorMulligan iid | iid == toId attrs -> do
      push $ FinishedWithMulligan iid
      pure i
    AddToDiscard iid pc | attrs `is` iid -> do
      push $ RemovedFromGame (PlayerCard pc)
      pure i
    DiscardCard iid _ cardId | attrs `is` iid -> do
      let card = fromJustNote "must be in hand" $ find @[Card] ((== cardId) . toCardId) attrs.hand
      pushAll [RemoveCardFromHand iid cardId, RemovedFromGame card]
      pure i
    Do (DiscardCard iid _ _) | attrs `is` iid -> pure i
    DrawCards cardDraw | attrs `is` cardDraw.investigator -> pure i
    _ -> GavriellaMizrah . (`with` meta) <$> runMessage msg attrs

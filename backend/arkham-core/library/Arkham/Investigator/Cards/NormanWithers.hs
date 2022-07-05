module Arkham.Investigator.Cards.NormanWithers where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Card
import Arkham.Card.Cost
import Arkham.Criteria
import Arkham.Game.Helpers
import Arkham.Helpers
import Arkham.Investigator.Runner
import Arkham.Matcher hiding (PlayCard)
import Arkham.Message
import Arkham.Target

newtype Metadata = Metadata { playedFromTopOfDeck :: Bool }
  deriving stock (Show, Generic, Eq)
  deriving anyclass (ToJSON, FromJSON)

newtype NormanWithers = NormanWithers (InvestigatorAttrs `With` Metadata)
  deriving anyclass IsInvestigator
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

normanWithers :: InvestigatorCard NormanWithers
normanWithers = investigator
  (NormanWithers . (`with` Metadata False))
  Cards.normanWithers
  Stats
    { health = 6
    , sanity = 8
    , willpower = 4
    , intellect = 5
    , combat = 2
    , agility = 1
    }

instance HasModifiersFor NormanWithers where
  getModifiersFor _ target (NormanWithers (a `With` metadata))
    | isTarget a target
    = pure
      $ toModifiers a
      $ TopCardOfDeckIsRevealed
      : [ CanPlayTopOfDeck AnyCard | not (playedFromTopOfDeck metadata) ]
  getModifiersFor _ (CardIdTarget cid) (NormanWithers (a `With` _)) =
    case unDeck (investigatorDeck a) of
      x : _ | toCardId x == cid ->
        pure $ toModifiers a [ReduceCostOf (CardWithId cid) 1]
      _ -> pure []
  getModifiersFor _ _ _ = pure []

instance HasAbilities NormanWithers where
  getAbilities (NormanWithers (a `With` _)) =
    [ restrictedAbility
          a
          1
          (Self
          <> InvestigatorExists (TopCardOfDeckIs WeaknessCard)
          <> CanManipulateDeck
          )
        $ ForcedAbility AnyWindow
    ]

instance HasTokenValue NormanWithers where
  getTokenValue iid ElderSign (NormanWithers (a `With` _)) | iid == toId a = do
    let
      x = case unDeck (investigatorDeck a) of
        [] -> 0
        c : _ -> maybe 0 toPrintedCost (cdCost $ toCardDef c)
    pure $ TokenValue ElderSign (PositiveModifier x)
  getTokenValue _ token _ = pure $ TokenValue token mempty

instance RunMessage NormanWithers where
  runMessage msg nw@(NormanWithers (a `With` metadata)) = case msg of
    UseCardAbility iid source _ 1 _ | isSource a source ->
      nw <$ push (DrawCards iid 1 False)
    When (RevealToken _ iid token)
      | iid == toId a && tokenFace token == ElderSign -> do
        nw <$ push
          (chooseOne iid
          $ Label "Do not swap" []
          : [ TargetLabel
                (CardIdTarget $ toCardId c)
                [DrawCards iid 1 False, PutOnTopOfDeck iid c]
            | c <- mapMaybe (preview _PlayerCard) (investigatorHand a)
            ]
          )
    BeginRound -> NormanWithers . (`with` Metadata False) <$> runMessage msg a
    PlayCard iid card _ False | iid == toId a ->
      case unDeck (investigatorDeck a) of
        c : _ | toCardId c == toCardId card ->
          NormanWithers . (`with` Metadata True) <$> runMessage msg a
        _ -> NormanWithers . (`with` metadata) <$> runMessage msg a
    _ -> NormanWithers . (`with` metadata) <$> runMessage msg a

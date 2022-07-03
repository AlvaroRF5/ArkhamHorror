module Arkham.Investigator.Cards.LeoAnderson
  ( leoAnderson
  , LeoAnderson(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Card
import Arkham.Card.Id
import Arkham.Cost
import Arkham.Criteria
import Arkham.Game.Helpers
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Matcher hiding ( PlayCard )
import Arkham.Message
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window
import Arkham.Zone

newtype Metadata = Metadata { responseCard :: Maybe CardId }
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

newtype LeoAnderson = LeoAnderson (InvestigatorAttrs `With` Metadata)
  deriving anyclass IsInvestigator
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

leoAnderson :: InvestigatorCard LeoAnderson
leoAnderson = investigator
  (LeoAnderson . (`with` Metadata Nothing))
  Cards.leoAnderson
  Stats
    { health = 8
    , sanity = 6
    , willpower = 4
    , intellect = 3
    , combat = 4
    , agility = 1
    }

instance HasModifiersFor LeoAnderson where
  getModifiersFor _ (CardIdTarget cid) (LeoAnderson (attrs `With` metadata))
    | Just cid == responseCard metadata
    = pure $ toModifiers attrs [ReduceCostOf (CardWithId cid) 1]
  getModifiersFor _ _ _ = pure []

instance HasAbilities LeoAnderson where
  getAbilities (LeoAnderson a) =
    [ restrictedAbility
          a
          1
          (Self <> PlayableCardExistsWithCostReduction
            1
            (InHandOf You <> BasicCardMatch IsAlly)
          )
        $ ReactionAbility (TurnBegins Timing.After You) Free
    ]

instance HasTokenValue LeoAnderson where
  getTokenValue iid ElderSign (LeoAnderson attrs) | iid == toId attrs = do
    pure $ TokenValue ElderSign (PositiveModifier 2)
  getTokenValue _ token _ = pure $ TokenValue token mempty

instance RunMessage LeoAnderson where
  runMessage msg i@(LeoAnderson (attrs `With` metadata)) = case msg of
    UseCardAbility iid source windows' 1 payment | isSource attrs source -> do
      results <- selectList (InHandOf You <> BasicCardMatch IsAlly)
      cards <- filterM
        (getIsPlayableWithResources
          iid
          source
          (investigatorResources attrs + 1)
          UnpaidCost
          [Window Timing.When (Window.DuringTurn iid)]
        )
        results
      push $ chooseOne
        iid
        [ TargetLabel
            target
            [UseCardAbilityChoiceTarget iid source windows' 1 payment target]
        | c <- cards
        , let target = CardIdTarget (toCardId c)
        ]
      pure i
    UseCardAbilityChoiceTarget iid source _ 1 _ (CardIdTarget cid)
      | isSource attrs source -> do
        pushAll [PayCardCost iid cid, PlayCard iid cid Nothing False, ResetMetadata (toTarget attrs)]
        pure . LeoAnderson $ attrs `with` Metadata (Just cid)
    ResetMetadata (isTarget attrs -> True) ->
      pure . LeoAnderson $ attrs `with` Metadata Nothing
    ResolveToken _drawnToken ElderSign iid | iid == toId attrs -> do
      push $ Search
        iid
        (toSource attrs)
        (toTarget attrs)
        [(FromTopOfDeck 3, ShuffleBackIn)]
        IsAlly
        (DrawFound iid 1)
      pure i
    _ -> LeoAnderson . (`with` metadata) <$> runMessage msg attrs

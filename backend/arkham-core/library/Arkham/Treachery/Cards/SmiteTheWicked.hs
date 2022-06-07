module Arkham.Treachery.Cards.SmiteTheWicked where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Card
import Arkham.Classes
import Arkham.Id
import Arkham.Matcher
import Arkham.Message hiding (InvestigatorEliminated)
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Runner

newtype SmiteTheWicked = SmiteTheWicked TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

smiteTheWicked :: TreacheryCard SmiteTheWicked
smiteTheWicked = treachery SmiteTheWicked Cards.smiteTheWicked

instance HasAbilities SmiteTheWicked where
  getAbilities (SmiteTheWicked a) =
    [ mkAbility a 1 $ ForcedAbility $ OrWindowMatcher
        [ GameEnds Timing.When
        , InvestigatorEliminated Timing.When (InvestigatorWithId iid)
        ]
    | iid <- maybeToList (treacheryOwner a)
    ]

instance RunMessage SmiteTheWicked where
  runMessage msg t@(SmiteTheWicked attrs@TreacheryAttrs {..}) = case msg of
    Revelation _iid source | isSource attrs source ->
      t <$ push (DiscardEncounterUntilFirst source (CardWithType EnemyType))
    RequestedEncounterCard source mcard | isSource attrs source -> case mcard of
      Nothing -> pure t
      Just card -> do
        let
          ownerId = fromJustNote "has to be set" treacheryOwner
          enemyId = EnemyId $ toCardId card
        farthestLocations <- selectList $ FarthestLocationFromYou Anywhere
        t <$ pushAll
          [ CreateEnemy (EncounterCard card)
          , AttachTreachery treacheryId (EnemyTarget enemyId)
          , chooseOne
            ownerId
            [ EnemySpawn Nothing lid enemyId | lid <- farthestLocations ]
          ]
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      let investigator = fromJustNote "missing investigator" treacheryOwner
      in t <$ push (SufferTrauma investigator 0 1)
    _ -> SmiteTheWicked <$> runMessage msg attrs

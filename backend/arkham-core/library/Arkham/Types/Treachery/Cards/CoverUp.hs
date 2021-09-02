module Arkham.Types.Treachery.Cards.CoverUp
  ( CoverUp(..)
  , coverUp
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.GameValue
import Arkham.Types.Matcher hiding (DiscoverClues)
import qualified Arkham.Types.Matcher as Matcher
import Arkham.Types.Message hiding (InvestigatorEliminated)
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype CoverUp = CoverUp TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env)
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

coverUp :: TreacheryCard CoverUp
coverUp = treacheryWith CoverUp Cards.coverUp (cluesL ?~ 3)

coverUpClues :: TreacheryAttrs -> Int
coverUpClues TreacheryAttrs { treacheryClues } =
  fromJustNote "must be set" treacheryClues

instance HasAbilities CoverUp where
  getAbilities (CoverUp a) =
    restrictedAbility
        a
        1
        (OnSameLocation <> CluesOnThis (AtLeast $ Static 1))
        (ReactionAbility
          (Matcher.DiscoverClues Timing.When You YourLocation $ AtLeast $ Static
            1
          )
          Free
        )
      : [ restrictedAbility a 2 (CluesOnThis $ AtLeast $ Static 1)
          $ ForcedAbility
          $ OrWindowMatcher
              [ GameEnds Timing.When
              , InvestigatorEliminated Timing.When (InvestigatorWithId iid)
              ]
        | iid <- maybeToList (treacheryOwner a)
        ]

instance TreacheryRunner env => RunMessage env CoverUp where
  runMessage msg t@(CoverUp attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> t <$ pushAll
      [ RemoveCardFromHand iid (toCardId attrs)
      , AttachTreachery treacheryId (InvestigatorTarget iid)
      ]
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      cluesToRemove <- withQueue $ \queue -> do
        let
          (before, after) = flip break queue $ \case
            DiscoverClues{} -> True
            _ -> False
          (DiscoverClues _ _ m _, remaining) = case after of
            [] -> error "DiscoverClues has to be present"
            (x : xs) -> (x, xs)
        (before <> remaining, m)
      let remainingClues = max 0 (coverUpClues attrs - cluesToRemove)
      pure $ CoverUp (attrs { treacheryClues = Just remainingClues })
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      withTreacheryInvestigator
        attrs
        \tormented -> t <$ push (SufferTrauma tormented 0 1)
    _ -> CoverUp <$> runMessage msg attrs

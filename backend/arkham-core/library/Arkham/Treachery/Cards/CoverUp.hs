module Arkham.Treachery.Cards.CoverUp (
  CoverUp (..),
  coverUp,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Matcher hiding (DiscoverClues)
import Arkham.Matcher qualified as Matcher
import Arkham.Message hiding (InvestigatorEliminated)
import Arkham.Timing qualified as Timing
import Arkham.Token
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner
import Arkham.Window (Window, windowType)
import Arkham.Window qualified as Window

newtype CoverUp = CoverUp TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor)
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

coverUp :: TreacheryCard CoverUp
coverUp = treacheryWith CoverUp Cards.coverUp (tokensL %~ setTokens Clue 3)

instance HasAbilities CoverUp where
  getAbilities (CoverUp a) =
    restrictedAbility
      a
      1
      (OnSameLocation <> CluesOnThis (atLeast 1))
      (freeReaction (Matcher.DiscoverClues Timing.When You YourLocation $ atLeast 1))
      : [ restrictedAbility a 2 (CluesOnThis $ atLeast 1)
          $ ForcedAbility
          $ OrWindowMatcher
            [ GameEnds Timing.When
            , InvestigatorEliminated Timing.When (InvestigatorWithId iid)
            ]
        | iid <- toList (treacheryOwner a)
        ]

toClueCount :: [Window] -> Int
toClueCount = \case
  ((windowType -> Window.DiscoverClues _ _ _ n) : _) -> n
  _ -> error "Invalid call"

instance RunMessage CoverUp where
  runMessage msg t@(CoverUp attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid (isSource attrs -> True) -> do
      push $ AttachTreachery treacheryId (toTarget iid)
      pure t
    UseCardAbility _ (isSource attrs -> True) 1 (toClueCount -> n) _ -> do
      popMessageMatching_ $ \case
        Do InvestigatorDiscoverClues {} -> True
        _ -> False
      pure $ CoverUp $ attrs & tokensL %~ subtractTokens Clue n
    UseThisAbility _ (isSource attrs -> True) 2 -> do
      withTreacheryInvestigator attrs $ \tormented -> push (SufferTrauma tormented 0 1)
      pure t
    _ -> CoverUp <$> runMessage msg attrs

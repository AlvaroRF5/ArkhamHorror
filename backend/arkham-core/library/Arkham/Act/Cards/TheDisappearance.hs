module Arkham.Act.Cards.TheDisappearance
  ( TheDisappearance(..)
  , theDisappearance
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.CampaignLogKey
import Arkham.Classes
import Arkham.Investigator.Types ( Field (..) )
import Arkham.Matcher
import Arkham.Message hiding (InvestigatorEliminated)
import Arkham.Projection
import Arkham.Timing qualified as Timing

newtype TheDisappearance = TheDisappearance ActAttrs
  deriving anyclass (IsAct, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theDisappearance :: ActCard TheDisappearance
theDisappearance = act (1, A) TheDisappearance Cards.theDisappearance Nothing

instance HasAbilities TheDisappearance where
  getAbilities (TheDisappearance a) =
    [mkAbility a 1 $ ForcedAbility $ InvestigatorEliminated Timing.When You]

instance RunMessage TheDisappearance where
  runMessage msg a@(TheDisappearance attrs) = case msg of
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs -> do
      -- Note, you can't actually trigger this
      pushAll [Record YouAreBeingHunted, RevertAct aid]
      pure a
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      clues <- field InvestigatorClues iid
      pushAll
        [ RemoveAllClues (InvestigatorTarget iid)
        , PlaceClues (toTarget attrs) clues
        ]
      pure a
    _ -> TheDisappearance <$> runMessage msg attrs

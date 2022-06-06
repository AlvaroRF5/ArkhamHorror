module Arkham.Location.Cards.DowntownArkhamAsylum
  ( DowntownArkhamAsylum(..)
  , downtownArkhamAsylum
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (downtownArkhamAsylum)
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype DowntownArkhamAsylum = DowntownArkhamAsylum LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

downtownArkhamAsylum :: LocationCard DowntownArkhamAsylum
downtownArkhamAsylum = location
  DowntownArkhamAsylum
  Cards.downtownArkhamAsylum
  4
  (PerPlayer 2)
  Triangle
  [Moon, T]

instance HasAbilities DowntownArkhamAsylum where
  getAbilities (DowntownArkhamAsylum x) | locationRevealed x =
    withBaseAbilities x $
      [ restrictedAbility
          x
          1
          (Here <> InvestigatorExists (You <> InvestigatorWithAnyHorror))
          (ActionAbility Nothing $ ActionCost 1)
        & abilityLimitL
        .~ PlayerLimit PerGame 1
      ]
  getAbilities (DowntownArkhamAsylum attrs) =
    getAbilities attrs

instance LocationRunner env => RunMessage DowntownArkhamAsylum where
  runMessage msg l@(DowntownArkhamAsylum attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ push (HealHorror (InvestigatorTarget iid) 3)
    _ -> DowntownArkhamAsylum <$> runMessage msg attrs

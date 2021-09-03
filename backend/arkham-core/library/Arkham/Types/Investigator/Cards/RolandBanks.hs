module Arkham.Types.Investigator.Cards.RolandBanks
  ( RolandBanks(..)
  , rolandBanks
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Id
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Matcher
import Arkham.Types.Message hiding (EnemyDefeated)
import Arkham.Types.Query
import qualified Arkham.Types.Timing as Timing

newtype RolandBanks = RolandBanks InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor env)
  deriving newtype (Show, ToJSON, FromJSON, Entity)

rolandBanks :: RolandBanks
rolandBanks = RolandBanks $ baseAttrs
  "01001"
  ("Roland Banks" <:> "The Fed")
  Guardian
  Stats
    { health = 9
    , sanity = 5
    , willpower = 3
    , intellect = 3
    , combat = 4
    , agility = 2
    }
  [Agency, Detective]

instance HasAbilities RolandBanks where
  getAbilities (RolandBanks a) =
    [ restrictedAbility
          a
          1
          (Self <> OnLocation LocationWithAnyClues)
          (ReactionAbility (EnemyDefeated Timing.After You AnyEnemy) Free)
        & (abilityLimitL .~ PlayerLimit PerRound 1)
    ]

instance HasCount ClueCount env LocationId => HasTokenValue env RolandBanks where
  getTokenValue (RolandBanks attrs) iid ElderSign | iid == toId attrs = do
    locationClueCount <- unClueCount <$> getCount (investigatorLocation attrs)
    pure $ TokenValue ElderSign (PositiveModifier locationClueCount)
  getTokenValue _ _ token = pure $ TokenValue token mempty

instance InvestigatorRunner env => RunMessage env RolandBanks where
  runMessage msg rb@(RolandBanks a) = case msg of
    UseCardAbility _ source _ 1 _ | isSource a source -> rb <$ push
      (DiscoverCluesAtLocation (toId a) (investigatorLocation a) 1 Nothing)
    _ -> RolandBanks <$> runMessage msg a

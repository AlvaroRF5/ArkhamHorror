module Arkham.Act.Cards.TheParisianConspiracyV2
  ( TheParisianConspiracyV2(..)
  , theParisianConspiracyV2
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Attrs
import qualified Arkham.Act.Cards as Cards
import Arkham.Act.Runner
import Arkham.Classes
import Arkham.Criteria
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message hiding (When)
import Arkham.Target
import Arkham.Timing

newtype TheParisianConspiracyV2 = TheParisianConspiracyV2 ActAttrs
  deriving anyclass (IsAct, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theParisianConspiracyV2 :: ActCard TheParisianConspiracyV2
theParisianConspiracyV2 =
  act (1, A) TheParisianConspiracyV2 Cards.theParisianConspiracyV2
    $ Just
    $ GroupClueCost (PerPlayer 2) Anywhere

instance HasAbilities TheParisianConspiracyV2 where
  getAbilities (TheParisianConspiracyV2 a) =
    [ restrictedAbility a 1 (DoomCountIs $ AtLeast $ Static 3)
        $ Objective
        $ ForcedAbility
        $ RoundEnds When
    ]

instance ActRunner env => RunMessage TheParisianConspiracyV2 where
  runMessage msg a@(TheParisianConspiracyV2 attrs) = case msg of
    AdvanceAct aid _ advanceMode | aid == actId attrs && onSide B attrs -> do
      theOrganist <-
        fromJustNote "The Organist was not set aside"
        . listToMaybe
        <$> getSetAsideCardsMatching (CardWithTitle "The Organist")
      case advanceMode of
        AdvancedWithClues -> do
          locationIds <- selectList $ FarthestLocationFromAll Anywhere
          leadInvestigatorId <- getLeadInvestigatorId
          pushAll
            [ chooseOrRunOne
              leadInvestigatorId
              [ TargetLabel
                  (LocationTarget lid)
                  [CreateEnemyAt theOrganist lid Nothing]
              | lid <- locationIds
              ]
            , AdvanceActDeck (actDeckId attrs) (toSource attrs)
            ]
        _ -> do
          investigatorIds <- selectList Anyone
          locationId <- selectJust LeadInvestigatorLocation
          pushAll
            $ [ InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 2
              | iid <- investigatorIds
              ]
            <> [ CreateEnemyAt theOrganist locationId Nothing
               , AdvanceActDeck (actDeckId attrs) (toSource attrs)
               ]
      pure a
    _ -> TheParisianConspiracyV2 <$> runMessage msg attrs

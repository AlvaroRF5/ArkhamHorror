module Arkham.Agenda.Cards.TheHierophantV (
  TheHierophantV (..),
  theHierophantV,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Runner
import Arkham.Card
import Arkham.Classes
import Arkham.GameValue
import Arkham.Id
import Arkham.Matcher
import Arkham.Message hiding (EnemyDefeated)
import Arkham.Timing qualified as Timing
import Arkham.Trait (Trait (Cultist, SilverTwilight))
import Arkham.Window (Window (..))
import Arkham.Window qualified as Window

newtype TheHierophantV = TheHierophantV AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theHierophantV :: AgendaCard TheHierophantV
theHierophantV = agenda (1, A) TheHierophantV Cards.theHierophantV (Static 8)

instance HasAbilities TheHierophantV where
  getAbilities (TheHierophantV a) =
    [ mkAbility a 1 $ ForcedAbility $ EnemyDefeated Timing.When You ByAny $ EnemyWithTrait SilverTwilight
    ]

-- given a list of investigators and a list of cultists have each investigator choose a cultist to draw
buildDrawCultists :: [Card] -> NonEmpty InvestigatorId -> NonEmpty EncounterCard -> Message
buildDrawCultists focused (investigator :| []) cards =
  Run
    [ FocusCards focused
    , chooseOne
        investigator
        [ targetLabel (toCardId card) [UnfocusCards, InvestigatorDrewEncounterCard investigator card]
        | card <- toList cards
        ]
    ]
buildDrawCultists focused (investigator :| (nextInvestigator : remainingInvestigators)) cards =
  Run
    [ FocusCards focused
    , chooseOne
        investigator
        [ targetLabel
          (toCardId card)
          ( UnfocusCards
              : InvestigatorDrewEncounterCard investigator card
              : [ buildDrawCultists
                  (deleteFirst (toCard card) focused)
                  (nextInvestigator :| remainingInvestigators)
                  rest'
                | rest' <- maybeToList (nonEmpty rest)
                ]
          )
        | (card, rest) <- eachWithRest (toList cards)
        ]
    ]

instance RunMessage TheHierophantV where
  runMessage msg a@(TheHierophantV attrs) = case msg of
    AdvanceAgenda aid | aid == toId attrs && onSide B attrs -> do
      lead <- getLead
      pushAll
        [DiscardTopOfEncounterDeck lead 5 (toSource attrs) (Just $ toTarget attrs), advanceAgendaDeck attrs]
      pure a
    DiscardedTopOfEncounterDeck _ cards _ (isTarget attrs -> True) -> do
      let mCultists = nonEmpty $ filter (`cardMatch` (CardWithTrait Cultist <> CardWithType EnemyType)) cards
      for_ mCultists $ \cultists -> do
        mInvestigators <- nonEmpty <$> getInvestigators
        case mInvestigators of
          Just investigators -> do
            push $ buildDrawCultists (map toCard cards) investigators cultists
          Nothing -> error "No investigators"
      pure a
    UseCardAbility _ (isSource attrs -> True) 1 (defeatedEnemy -> enemy) _ -> do
      enemiesWithDoom <- selectList $ EnemyAt (locationWithEnemy enemy) <> EnemyWithAnyDoom
      pushAll $
        concat
          [[RemoveDoom (toSource attrs) (toTarget enemy') 1, PlaceDoomOnAgenda] | enemy' <- enemiesWithDoom]
      pure a
    _ -> TheHierophantV <$> runMessage msg attrs

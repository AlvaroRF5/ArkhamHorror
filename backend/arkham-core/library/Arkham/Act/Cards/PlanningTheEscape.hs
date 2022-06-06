module Arkham.Act.Cards.PlanningTheEscape
  ( PlanningTheEscape(..)
  , planningTheEscape
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Attrs
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Card
import Arkham.Card.EncounterCard
import Arkham.Classes
import Arkham.Criteria
import Arkham.Decks
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.ScenarioLogKey
import Arkham.SkillType
import Arkham.Target
import Arkham.Trait

newtype PlanningTheEscape = PlanningTheEscape ActAttrs
  deriving anyclass IsAct
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

planningTheEscape :: ActCard PlanningTheEscape
planningTheEscape =
  act (3, A) PlanningTheEscape Cards.planningTheEscape Nothing

instance Query LocationMatcher env => HasModifiersFor PlanningTheEscape where
  getModifiersFor _ (LocationTarget lid) (PlanningTheEscape attrs) = do
    targets <- select UnrevealedLocation
    pure
      [ toModifier attrs (TraitRestrictedModifier ArkhamAsylum Blank)
      | lid `member` targets
      ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities PlanningTheEscape where
  getAbilities (PlanningTheEscape x) =
    [ restrictedAbility
          x
          1
          (Remembered
            (RememberedLengthIs $ AtLeast $ Static 4)
            [ KnowTheGuardsPatrols
            , SetAFireInTheKitchen
            , IncitedAFightAmongstThePatients
            , ReleasedADangerousPatient
            , RecalledTheWayOut
            , DistractedTheGuards
            ]
          )
        $ Objective
        $ ForcedAbility AnyWindow
    ]

instance ActRunner env => RunMessage PlanningTheEscape where
  runMessage msg a@(PlanningTheEscape attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AdvanceAct (toId a) (toSource attrs) AdvancedWithOther)
    AdvanceAct aid _ _ | aid == toId a && onSide B attrs -> do
      enemyCards <-
        filter ((== EnemyType) . toCardType)
        . mapMaybe (preview _EncounterCard . unUnderneathCard)
        <$> getList ActDeck
      discardedCards <- map unDiscardedEncounterCard <$> getList ()

      let
        monsterCount =
          count (member Monster . toTraits) (enemyCards <> discardedCards)

      a <$ pushAll
        ([ShuffleIntoEncounterDeck enemyCards, ShuffleEncounterDiscardBackIn]
        <> [ DiscardEncounterUntilFirst
               (toSource attrs)
               (CardWithType EnemyType <> CardWithTrait Monster)
           | monsterCount >= 3
           ]
        <> [AdvanceActDeck (actDeckId attrs) $ toSource attrs]
        )
    RequestedEncounterCard source mcard | isSource attrs source -> do
      leadInvestigatorId <- getLeadInvestigatorId
      for_ mcard $ \card -> do
        investigators <- selectList (InvestigatorWithLowestSkill SkillWillpower)
        case investigators of
          [] -> error "Should have at least one investigator"
          is -> push
            (chooseOrRunOne
              leadInvestigatorId
              [ TargetLabel
                  (InvestigatorTarget i)
                  [InvestigatorDrewEncounterCard i card]
              | i <- is
              ]
            )
      pure a
    _ -> PlanningTheEscape <$> runMessage msg attrs

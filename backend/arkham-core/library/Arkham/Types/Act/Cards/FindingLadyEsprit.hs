module Arkham.Types.Act.Cards.FindingLadyEsprit
  ( FindingLadyEsprit(..)
  , findingLadyEsprit
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Assets
import Arkham.EncounterCard
import Arkham.EncounterSet
import qualified Arkham.Enemy.Cards as Enemies
import Arkham.PlayerCard
import qualified Arkham.Treachery.Cards as Treacheries
import Arkham.Types.Act.Attrs
import Arkham.Types.Act.Helpers
import Arkham.Types.Act.Runner
import Arkham.Types.Card
import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.Window
import Data.Maybe (fromJust)

newtype FindingLadyEsprit = FindingLadyEsprit ActAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasModifiersFor env)

findingLadyEsprit :: FindingLadyEsprit
findingLadyEsprit =
  FindingLadyEsprit $ baseAttrs "81005" "Finding Lady Esprit" (Act 1 A) Nothing

instance ActionRunner env => HasActions env FindingLadyEsprit where
  getActions _ FastPlayerWindow (FindingLadyEsprit attrs@ActAttrs {..}) = do
    investigatorIds <- investigatorsInABayouLocation
    requiredClueCount <- getPlayerCountValue (PerPlayer 1)
    canAdvance' <- (>= requiredClueCount)
      <$> getSpendableClueCount investigatorIds
    pure [ AdvanceAct actId (toSource attrs) | canAdvance' ]
  getActions i window (FindingLadyEsprit x) = getActions i window x

investigatorsInABayouLocation
  :: ( MonadReader env m
     , HasSet LocationId env [Trait]
     , HasSet InvestigatorId env (HashSet LocationId)
     )
  => m [InvestigatorId]
investigatorsInABayouLocation = bayouLocations >>= getSetList

bayouLocations
  :: (MonadReader env m, HasSet LocationId env [Trait])
  => m (HashSet LocationId)
bayouLocations = getSet [Bayou]

nonBayouLocations
  :: ( MonadReader env m
     , HasSet LocationId env ()
     , HasSet LocationId env [Trait]
     )
  => m (HashSet LocationId)
nonBayouLocations = difference <$> getLocationSet <*> bayouLocations

instance ActRunner env => RunMessage env FindingLadyEsprit where
  runMessage msg a@(FindingLadyEsprit attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ | aid == actId && onSide A attrs -> do
      investigatorIds <- investigatorsInABayouLocation
      requiredClueCount <- getPlayerCountValue (PerPlayer 1)
      pushAll
        (SpendClues requiredClueCount investigatorIds
        : [ chooseOne iid [AdvanceAct aid (toSource attrs)]
          | iid <- investigatorIds
          ]
        )
      pure $ FindingLadyEsprit $ attrs & (sequenceL .~ Act 1 B)
    AdvanceAct aid _ | aid == actId && onSide B attrs -> do
      ladyEspritSpawnLocation <-
        fromJust . headMay . setToList <$> bayouLocations
      ladyEsprit <- PlayerCard <$> genPlayerCard Assets.ladyEsprit
      a <$ pushAll
        [ CreateStoryAssetAt ladyEsprit ladyEspritSpawnLocation
        , PutSetAsideIntoPlay (SetAsideLocationsTarget mempty)
        , NextAdvanceActStep aid 2
        ]
    NextAdvanceActStep aid 2 | aid == actId && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      curseOfTheRougarouSet <- gatherEncounterSet
        EncounterSet.CurseOfTheRougarou
      rougarouSpawnLocations <- setToList <$> nonBayouLocations
      theRougarou <- EncounterCard <$> genEncounterCard Enemies.theRougarou
      curseOfTheRougarou <- PlayerCard
        <$> genPlayerCard Treacheries.curseOfTheRougarou
      a <$ pushAll
        ([ chooseOne
             leadInvestigatorId
             [ CreateEnemyAt theRougarou lid Nothing
             | lid <- rougarouSpawnLocations
             ]
         ]
        <> [ ShuffleEncounterDiscardBackIn
           , ShuffleIntoEncounterDeck curseOfTheRougarouSet
           , AddCampaignCardToDeck
             leadInvestigatorId
             Treacheries.curseOfTheRougarou
           , CreateWeaknessInThreatArea curseOfTheRougarou leadInvestigatorId
           , NextAct aid "81006"
           ]
        )
    _ -> FindingLadyEsprit <$> runMessage msg attrs

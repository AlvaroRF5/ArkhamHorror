module Arkham.Types.Location.Cards.StudyAberrantGateway
  ( StudyAberrantGateway(..)
  , studyAberrantGateway
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (studyAberrantGateway)
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Game.Helpers
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Window

newtype StudyAberrantGateway = StudyAberrantGateway LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

studyAberrantGateway :: LocationCard StudyAberrantGateway
studyAberrantGateway = location
  StudyAberrantGateway
  Cards.studyAberrantGateway
  3
  (PerPlayer 1)
  Circle
  [T]

instance HasModifiersFor env StudyAberrantGateway where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env StudyAberrantGateway where
  getActions iid NonFast (StudyAberrantGateway attrs)
    | iid `elem` locationInvestigators attrs
    = withBaseActions iid NonFast attrs $ do
      leadInvestigatorId <- getLeadInvestigatorId
      pure
        [ UseAbility
            iid
            (mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 2)
            )
        | leadInvestigatorId == iid
        ]
  getActions iid window (StudyAberrantGateway attrs) =
    getActions iid window attrs

instance LocationRunner env => RunMessage env StudyAberrantGateway where
  runMessage msg l@(StudyAberrantGateway attrs@LocationAttrs {..}) =
    case msg of
      UseCardAbility iid (LocationSource lid) _ 1 _ | lid == locationId ->
        l <$ unshiftMessage (DrawCards iid 3 False)
      When (EnemySpawnAtLocationMatching _ locationMatcher _) -> do
        inPlay <- isJust <$> getId @(Maybe LocationId) locationMatcher
        l <$ unless
          inPlay
          (unshiftMessage (PlaceLocationMatching locationMatcher))
      _ -> StudyAberrantGateway <$> runMessage msg attrs

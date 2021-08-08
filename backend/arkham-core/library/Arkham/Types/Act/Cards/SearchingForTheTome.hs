module Arkham.Types.Act.Cards.SearchingForTheTome
  ( SearchingForTheTome(..)
  , searchingForTheTome
  ) where

import Arkham.Prelude

import qualified Arkham.Act.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Act.Attrs
import Arkham.Types.Act.Helpers
import Arkham.Types.Act.Runner
import Arkham.Types.Classes
import Arkham.Types.LocationId
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Query
import Arkham.Types.Resolution

newtype SearchingForTheTome = SearchingForTheTome ActAttrs
  deriving anyclass IsAct
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasModifiersFor env)

searchingForTheTome :: ActCard SearchingForTheTome
searchingForTheTome =
  act (3, A) SearchingForTheTome Cards.searchingForTheTome Nothing

instance ActionRunner env => HasActions env SearchingForTheTome where
  getActions i window (SearchingForTheTome x) = do
    mRestrictedHall <- getId @(Maybe LocationId)
      (LocationWithFullTitle "Exhibit Hall" "Restricted Hall")
    case mRestrictedHall of
      Just restrictedHall -> do
        mustAdvance <- (== 0) . unClueCount <$> getCount restrictedHall
        if mustAdvance
          then pure [mkAbility x 1 ForcedAbility]
          else getActions i window x
      Nothing -> getActions i window x

instance ActRunner env => RunMessage env SearchingForTheTome where
  runMessage msg a@(SearchingForTheTome attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ | aid == actId && onSide A attrs -> do
      push (AdvanceAct aid $ toSource attrs)
      pure . SearchingForTheTome $ attrs & sequenceL .~ Act 3 B
    AdvanceAct aid _ | aid == actId && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      a <$ push
        (chooseOne
          leadInvestigatorId
          [ Label
            "It's too dangerous to keep around. We have to destroy it. (-> R1)"
            [ScenarioResolution $ Resolution 1]
          , Label
            "It's too valuable to destroy. We have to keep it safe. (-> R2)"
            [ScenarioResolution $ Resolution 2]
          ]
        )
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AdvanceAct (toId attrs) (toSource attrs))
    _ -> SearchingForTheTome <$> runMessage msg attrs

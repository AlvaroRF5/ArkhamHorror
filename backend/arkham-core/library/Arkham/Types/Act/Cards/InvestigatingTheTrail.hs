module Arkham.Types.Act.Cards.InvestigatingTheTrail where

import Arkham.Prelude

import qualified Arkham.Act.Cards as Cards
import Arkham.EncounterCard
import qualified Arkham.Location.Cards as Locations
import Arkham.Types.Act.Attrs
import Arkham.Types.Act.Helpers
import Arkham.Types.Act.Runner
import Arkham.Types.CampaignLogKey
import Arkham.Types.Card
import Arkham.Types.Card.EncounterCard
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Matcher
import Arkham.Types.Message

newtype InvestigatingTheTrail = InvestigatingTheTrail ActAttrs
  deriving anyclass (IsAct, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities env)

investigatingTheTrail :: ActCard InvestigatingTheTrail
investigatingTheTrail = act
  (1, A)
  InvestigatingTheTrail
  Cards.investigatingTheTrail
  (Just $ GroupClueCost (PerPlayer 3) Anywhere)

instance ActRunner env => RunMessage env InvestigatingTheTrail where
  runMessage msg a@(InvestigatingTheTrail attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ | aid == actId && onSide B attrs -> do
      mRitualSiteId <- getLocationIdByName "Ritual Site"
      mainPathId <- getJustLocationIdByName "Main Path"
      when (isNothing mRitualSiteId) $ do
        ritualSiteId <- getRandom
        push (PlaceLocation ritualSiteId Locations.ritualSite)
      cultistsWhoGotAwayDefs <- map lookupEncounterCardDef
        <$> hasRecordSet CultistsWhoGotAway
      cultistsWhoGotAway <- traverse genEncounterCard cultistsWhoGotAwayDefs
      a <$ pushAll
        ([ CreateEnemyAt (EncounterCard card) mainPathId Nothing
         | card <- cultistsWhoGotAway
         ]
        <> [NextAct aid "01147"]
        )
    _ -> InvestigatingTheTrail <$> runMessage msg attrs

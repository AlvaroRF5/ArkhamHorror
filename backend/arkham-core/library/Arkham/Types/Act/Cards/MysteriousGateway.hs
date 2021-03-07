module Arkham.Types.Act.Cards.MysteriousGateway where

import Arkham.Prelude

import Arkham.Types.Act.Attrs
import Arkham.Types.Act.Helpers
import Arkham.Types.Act.Runner
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationMatcher
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target

newtype MysteriousGateway = MysteriousGateway ActAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasModifiersFor env)

mysteriousGateway :: MysteriousGateway
mysteriousGateway = MysteriousGateway $ baseAttrs
  "50012"
  "Mysterious Gateway"
  (Act 1 A)
  (Just $ RequiredClues (PerPlayer 3) (Just $ LocationWithTitle "Guest Hall"))

instance ActionRunner env => HasActions env MysteriousGateway where
  getActions i window (MysteriousGateway x) = getActions i window x

instance ActRunner env => RunMessage env MysteriousGateway where
  runMessage msg a@(MysteriousGateway attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ | aid == actId && onSide A attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      investigatorIds <- getSetList @InvestigatorId
        (LocationWithTitle "Guest Hall")
      requiredClues <- getPlayerCountValue (PerPlayer 3)
      unshiftMessages
        [ SpendClues requiredClues investigatorIds
        , chooseOne leadInvestigatorId [AdvanceAct aid (toSource attrs)]
        ]
      pure $ MysteriousGateway $ attrs & (sequenceL .~ Act 1 B)
    AdvanceAct aid _ | aid == actId && onSide B attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      investigatorIds <- getSetList @InvestigatorId
        (LocationWithTitle "Guest Hall")
      holeInTheWallId <- getRandom
      a <$ unshiftMessages
        ([PlaceLocation "50017" holeInTheWallId]
        <> [ chooseOne
             leadInvestigatorId
             [ TargetLabel
                 (InvestigatorTarget iid')
                 [ MoveTo iid' holeInTheWallId
                 , BeginSkillTest
                   iid'
                   (ActSource aid)
                   (InvestigatorTarget iid')
                   Nothing
                   SkillWillpower
                   4
                 ]
             | iid' <- investigatorIds
             ]
           , NextAct aid "01109"
           ]
        )
    FailedSkillTest iid _ (ActSource aid) SkillTestInitiatorTarget{} _ n
      | aid == actId -> a <$ unshiftMessages (replicate n (RandomDiscard iid))
    _ -> MysteriousGateway <$> runMessage msg attrs

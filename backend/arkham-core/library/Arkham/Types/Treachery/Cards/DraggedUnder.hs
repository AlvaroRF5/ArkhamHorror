module Arkham.Types.Treachery.Cards.DraggedUnder where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype DraggedUnder = DraggedUnder TreacheryAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

draggedUnder :: TreacheryId -> a -> DraggedUnder
draggedUnder uuid _ = DraggedUnder $ baseAttrs uuid "81026"

instance HasModifiersFor env DraggedUnder where
  getModifiersFor = noModifiersFor

instance HasActions env DraggedUnder where
  getActions i window (DraggedUnder attrs) = getActions i window attrs

instance (TreacheryRunner env) => RunMessage env DraggedUnder where
  runMessage msg t@(DraggedUnder attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ unshiftMessage (RevelationSkillTest iid source SkillAgility 3)
    MoveFrom iid _ | treacheryOnInvestigator iid attrs -> t <$ unshiftMessages
      [ InvestigatorAssignDamage iid (TreacherySource treacheryId) DamageAny 2 0
      , Discard (TreacheryTarget treacheryId)
      ]
    EndTurn iid | treacheryOnInvestigator iid attrs -> t <$ unshiftMessage
      (BeginSkillTest
        iid
        (TreacherySource treacheryId)
        (InvestigatorTarget iid)
        Nothing
        SkillAgility
        3
      )
    FailedSkillTest iid _ source _ _ _ | isSource attrs source -> t <$ when
      (isNothing treacheryAttachedTarget)
      (unshiftMessage $ AttachTreachery treacheryId (InvestigatorTarget iid))
    PassedSkillTest _ _ source _ _ _ | isSource attrs source ->
      t <$ unshiftMessage (Discard $ toTarget attrs)
    _ -> DraggedUnder <$> runMessage msg attrs

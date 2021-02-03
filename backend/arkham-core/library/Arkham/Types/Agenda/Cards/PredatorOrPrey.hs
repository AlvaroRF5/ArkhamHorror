module Arkham.Types.Agenda.Cards.PredatorOrPrey
  ( PredatorOrPrey(..)
  , predatorOrPrey
  )
where

import Arkham.Import
import qualified Arkham.Types.Action as Action
import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Runner

newtype PredatorOrPrey = PredatorOrPrey AgendaAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

predatorOrPrey :: PredatorOrPrey
predatorOrPrey =
  PredatorOrPrey $ baseAttrs "01121" "Predator or Prey?" (Agenda 1 A) (Static 6)

instance HasModifiersFor env PredatorOrPrey where
  getModifiersFor = noModifiersFor

instance HasActions env PredatorOrPrey where
  getActions iid NonFast (PredatorOrPrey attrs) = pure
    [ ActivateCardAbilityAction
        iid
        (mkAbility
          (toSource attrs)
          1
          (ActionAbility (Just Action.Resign) (ActionCost 1))
        )
    ]
  getActions _ _ _ = pure []

instance (AgendaRunner env) => RunMessage env PredatorOrPrey where
  runMessage msg a@(PredatorOrPrey attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B ->
      a <$ unshiftMessages
        [CreateEnemyEngagedWithPrey "01121b", NextAgenda aid "01122"]
    UseCardAbility iid (AgendaSource aid) _ 1 _ | aid == agendaId -> do
      unshiftMessage (Resign iid)
      PredatorOrPrey <$> runMessage msg attrs
    _ -> PredatorOrPrey <$> runMessage msg attrs

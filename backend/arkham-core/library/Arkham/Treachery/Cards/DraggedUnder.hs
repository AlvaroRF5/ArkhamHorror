module Arkham.Treachery.Cards.DraggedUnder where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Attrs
import Arkham.Treachery.Runner

newtype DraggedUnder = DraggedUnder TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

draggedUnder :: TreacheryCard DraggedUnder
draggedUnder = treachery DraggedUnder Cards.draggedUnder

instance HasAbilities DraggedUnder where
  getAbilities (DraggedUnder x) =
    [ restrictedAbility x 1 (InThreatAreaOf You) $ ForcedAbility $ Leaves
      Timing.When
      You
      Anywhere
    , restrictedAbility x 2 (InThreatAreaOf You) $ ForcedAbility $ TurnEnds
      Timing.When
      You
    ]

instance TreacheryRunner env => RunMessage env DraggedUnder where
  runMessage msg t@(DraggedUnder attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (RevelationSkillTest iid source SkillAgility 3)
    UseCardAbility iid source _ 1 _ | isSource attrs source -> t <$ pushAll
      [ InvestigatorAssignDamage iid source DamageAny 2 0
      , Discard $ toTarget attrs
      ]
    UseCardAbility iid source _ 2 _ | isSource attrs source ->
      t
        <$ push
             (BeginSkillTest
               iid
               source
               (InvestigatorTarget iid)
               Nothing
               SkillAgility
               3
             )
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> t <$ when
        (isNothing $ treacheryAttachedTarget attrs)
        (push $ AttachTreachery (toId attrs) (InvestigatorTarget iid))
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> t <$ push (Discard $ toTarget attrs)
    _ -> DraggedUnder <$> runMessage msg attrs

module Arkham.Location.Cards.InterviewRoomRestrainingChamber
  ( interviewRoomRestrainingChamber
  , InterviewRoomRestrainingChamber(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Helpers.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Message
import Arkham.ScenarioLogKey
import Arkham.SkillType
import Arkham.Target

newtype InterviewRoomRestrainingChamber = InterviewRoomRestrainingChamber LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

interviewRoomRestrainingChamber :: LocationCard InterviewRoomRestrainingChamber
interviewRoomRestrainingChamber = location
  InterviewRoomRestrainingChamber
  Cards.interviewRoomRestrainingChamber
  4
  (PerPlayer 1)

instance HasAbilities InterviewRoomRestrainingChamber where
  getAbilities (InterviewRoomRestrainingChamber attrs) = withBaseAbilities
    attrs
    [ restrictedAbility attrs 1 Here
      $ ActionAbility (Just Action.Parley)
      $ ActionCost 1
    ]

instance RunMessage InterviewRoomRestrainingChamber where
  runMessage msg l@(InterviewRoomRestrainingChamber attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $ chooseOne
        iid
        [ Label
          "Use {intellect}"
          [ BeginSkillTest
              iid
              (toSource attrs)
              (InvestigatorTarget iid)
              (Just Action.Parley)
              SkillIntellect
              4
          ]
        , Label
          "Use {combat}"
          [ BeginSkillTest
              iid
              (toSource attrs)
              (InvestigatorTarget iid)
              (Just Action.Parley)
              SkillIntellect
              4
          ]
        ]
      pure l
    PassedSkillTest _ _ (isSource attrs -> True) SkillTestInitiatorTarget{} _ _
      -> do
        push $ Remember InterviewedASubject
        pure l
    FailedSkillTest iid _ (isSource attrs -> True) SkillTestInitiatorTarget{} _ _
      -> do
        push $ InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 2
        pure l
    _ -> InterviewRoomRestrainingChamber <$> runMessage msg attrs

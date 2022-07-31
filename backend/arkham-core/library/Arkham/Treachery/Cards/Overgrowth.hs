module Arkham.Treachery.Cards.Overgrowth
  ( overgrowth
  , Overgrowth(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Game.Helpers
import Arkham.Helpers.Investigator
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype Overgrowth = Overgrowth TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

overgrowth :: TreacheryCard Overgrowth
overgrowth = treachery Overgrowth Cards.overgrowth

instance HasModifiersFor Overgrowth where
  getModifiersFor _ (InvestigatorTarget iid) (Overgrowth attrs) = do
    lid <- getJustLocation iid
    pure $ toModifiers attrs [ CannotExplore | treacheryOnLocation lid attrs ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities Overgrowth where
  getAbilities (Overgrowth a) =
    [ restrictedAbility a 1 OnSameLocation $ ActionAbility Nothing $ ActionCost
        1
    ]

instance RunMessage Overgrowth where
  runMessage msg t@(Overgrowth attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      lid <- getJustLocation iid
      withoutOvergrowth <- lid
        <=~> LocationWithoutTreachery (treacheryIs Cards.overgrowth)
      when withoutOvergrowth $ push $ AttachTreachery
        (toId attrs)
        (LocationTarget lid)
      pure t
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      let
        target = toTarget attrs
        beginSkillTest sType = BeginSkillTest iid source target Nothing sType 4
      t <$ push
        (chooseOne iid $ map beginSkillTest [SkillCombat, SkillIntellect])
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> t <$ push (Discard $ toTarget attrs)
    _ -> Overgrowth <$> runMessage msg attrs

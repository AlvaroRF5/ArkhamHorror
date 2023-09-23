module Arkham.Treachery.Cards.Punishment (
  punishment,
  Punishment (..),
)
where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.Message hiding (EnemyDefeated)
import Arkham.SkillType
import Arkham.Source
import Arkham.Timing qualified as Timing
import Arkham.Trait (Trait (Witch))
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner
import Control.Monad.Trans.Maybe

newtype Punishment = Punishment TreacheryAttrs
  deriving anyclass (IsTreachery)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

punishment :: TreacheryCard Punishment
punishment = treachery Punishment Cards.punishment

instance HasModifiersFor Punishment where
  getModifiersFor (InvestigatorTarget iid) (Punishment attrs) = do
    mModifiers <- runMaybeT $ do
      source <- MaybeT getSkillTestSource
      investigator <- MaybeT getSkillTestInvestigator
      guard $ isSource attrs source && iid == investigator
      guardM
        . lift
        . selectAny
        $ ExhaustedEnemy
        <> EnemyWithTrait Witch
        <> EnemyAt (locationWithInvestigator iid)
      pure SkillTestAutomaticallySucceeds

    pure $ toModifiers attrs $ maybeToList mModifiers
  getModifiersFor _ _ = pure []

instance HasAbilities Punishment where
  getAbilities (Punishment a) =
    [ restrictedAbility a 1 (InThreatAreaOf You)
        $ ForcedAbility
        $ EnemyDefeated Timing.After Anyone ByAny AnyEnemy
    ]

instance RunMessage Punishment where
  runMessage msg t@(Punishment attrs) = case msg of
    Revelation iid (isSource attrs -> True) ->
      t <$ push (AttachTreachery (toId attrs) $ toTarget iid)
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $ InvestigatorAssignDamage iid (toSource attrs) DamageAny 1 0
      pure t
    UseCardAbility iid (isSource attrs -> True) 2 _ _ -> do
      push $ beginSkillTest iid attrs attrs SkillWillpower 3
      pure t
    PassedSkillTest _ _ (isSource attrs -> True) SkillTestInitiatorTarget {} _ _ -> do
      push $ Discard (toSource attrs) (toTarget attrs)
      pure t
    _ -> Punishment <$> runMessage msg attrs

module Arkham.Treachery.Cards.ClawsOfSteam
  ( clawsOfSteam
  , ClawsOfSteam(..)
  ) where

import Arkham.Prelude

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.Game.Helpers
import Arkham.Message
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Arkham.Treachery.Runner
import Arkham.Treachery.Runner

newtype ClawsOfSteam = ClawsOfSteam TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

clawsOfSteam :: TreacheryCard ClawsOfSteam
clawsOfSteam = treachery ClawsOfSteam Cards.clawsOfSteam

instance RunMessage ClawsOfSteam where
  runMessage msg t@(ClawsOfSteam attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (RevelationSkillTest iid source SkillWillpower 3)
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> t <$ pushAll
        [ CreateWindowModifierEffect
          EffectRoundWindow
          (EffectModifiers $ toModifiers attrs [CannotMove])
          source
          (InvestigatorTarget iid)
        , InvestigatorAssignDamage
          iid
          (TreacherySource treacheryId)
          DamageAssetsFirst
          2
          0
        ]
    _ -> ClawsOfSteam <$> runMessage msg attrs

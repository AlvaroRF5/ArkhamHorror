module Arkham.Act.Cards.AscendingTheHillV1
  ( AscendingTheHillV1(..)
  , ascendingTheHillV1
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Attrs
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Runner
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Trait

newtype AscendingTheHillV1 = AscendingTheHillV1 ActAttrs
  deriving anyclass IsAct
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ascendingTheHillV1 :: ActCard AscendingTheHillV1
ascendingTheHillV1 =
  act (2, A) AscendingTheHillV1 Cards.ascendingTheHillV1 Nothing

instance HasModifiersFor env AscendingTheHillV1 where
  getModifiersFor _ (LocationTarget _) (AscendingTheHillV1 attrs) =
    pure $ toModifiers attrs [TraitRestrictedModifier Altered CannotPlaceClues]
  getModifiersFor _ _ _ = pure []

instance HasAbilities AscendingTheHillV1 where
  getAbilities (AscendingTheHillV1 x) =
    [ mkAbility x 1 $ ForcedAbility $ Enters Timing.When You $ LocationWithTitle
        "Sentinel Peak"
    ]

instance ActRunner env => RunMessage AscendingTheHillV1 where
  runMessage msg a@(AscendingTheHillV1 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AdvanceAct (toId attrs) source AdvancedWithOther)
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs ->
      a <$ push (AdvanceActDeck (actDeckId attrs) (toSource attrs))
    _ -> AscendingTheHillV1 <$> runMessage msg attrs

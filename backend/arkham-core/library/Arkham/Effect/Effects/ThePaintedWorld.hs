module Arkham.Effect.Effects.ThePaintedWorld (
  ThePaintedWorld (..),
  thePaintedWorld,
) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Event.Types (Field (..))
import Arkham.Game.Helpers
import Arkham.Projection

newtype ThePaintedWorld = ThePaintedWorld EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, NoThunks, NFData)

thePaintedWorld :: EffectArgs -> ThePaintedWorld
thePaintedWorld = ThePaintedWorld . uncurry4 (baseAttrs "03012")

instance HasModifiersFor ThePaintedWorld where
  getModifiersFor (EventTarget eid) (ThePaintedWorld a@EffectAttrs {..}) = do
    cardId <- field EventCardId eid
    pure
      $ toModifiers
        a
        [RemoveFromGameInsteadOfDiscard | toTarget cardId == effectTarget]
  getModifiersFor (CardIdTarget cardId) (ThePaintedWorld a@EffectAttrs {..}) = do
    -- Mainly used for cards like Crystallizer of Dreams that work with After you play effects
    pure
      $ toModifiers
        a
        [RemoveFromGameInsteadOfDiscard | toTarget cardId == effectTarget]
  getModifiersFor _ _ = pure []

instance RunMessage ThePaintedWorld where
  runMessage msg (ThePaintedWorld attrs) =
    ThePaintedWorld <$> runMessage msg attrs

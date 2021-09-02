module Arkham.Types.Treachery.Cards.CollapsingReality
  ( collapsingReality
  , CollapsingReality(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype CollapsingReality = CollapsingReality TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

collapsingReality :: TreacheryCard CollapsingReality
collapsingReality = treachery CollapsingReality Cards.collapsingReality

instance TreacheryRunner env => RunMessage env CollapsingReality where
  runMessage msg t@(CollapsingReality attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      lid <- getId @LocationId iid
      isExtradimensional <- member Extradimensional <$> getSet lid
      let
        revelationMsgs = if isExtradimensional
          then
            [ Discard (LocationTarget lid)
            , InvestigatorAssignDamage iid source DamageAny 1 0
            ]
          else [InvestigatorAssignDamage iid source DamageAny 2 0]
      t <$ pushAll (revelationMsgs <> [Discard (toTarget attrs)])
    _ -> CollapsingReality <$> runMessage msg attrs

module Arkham.Types.Treachery.Cards.Haunted
  ( Haunted(..)
  , haunted
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Source
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner
import Arkham.Types.Window

newtype Haunted = Haunted TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

haunted :: TreacheryCard Haunted
haunted = treachery Haunted Cards.haunted

instance HasModifiersFor env Haunted where
  getModifiersFor _ (InvestigatorTarget iid) (Haunted attrs) =
    pure $ toModifiers
      attrs
      [ AnySkillValue (-1) | treacheryOnInvestigator iid attrs ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasAbilities env Haunted where
  getAbilities iid (Window Timing.When NonFast) (Haunted a) =
    withTreacheryInvestigator a $ \tormented -> do
      investigatorLocationId <- getId @LocationId iid
      treacheryLocation <- getId tormented
      pure
        [ mkAbility a 1 $ ActionAbility Nothing $ ActionCost 2
        | treacheryLocation == investigatorLocationId
        ]
  getAbilities _ _ _ = pure []

instance (TreacheryRunner env) => RunMessage env Haunted where
  runMessage msg t@(Haunted attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AttachTreachery treacheryId $ InvestigatorTarget iid)
    UseCardAbility _ (TreacherySource tid) _ 1 _ | tid == treacheryId ->
      t <$ push (Discard (TreacheryTarget treacheryId))
    _ -> Haunted <$> runMessage msg attrs

module Arkham.Types.Treachery.Cards.Chronophobia
  ( chronophobia
  , Chronophobia(..)
  ) where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype Chronophobia = Chronophobia Attrs
  deriving newtype (Show, ToJSON, FromJSON)

chronophobia :: TreacheryId -> Maybe InvestigatorId -> Chronophobia
chronophobia uuid iid = Chronophobia $ weaknessAttrs uuid iid "02039"

instance HasModifiersFor env Chronophobia where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Chronophobia where
  getActions iid NonFast (Chronophobia a@Attrs {..}) =
    withTreacheryInvestigator a $ \tormented -> do
      investigatorLocationId <- getId @LocationId iid
      treacheryLocation <- getId tormented
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility (toSource a) 1 (ActionAbility Nothing $ ActionCost 2))
        | treacheryLocation == investigatorLocationId
        ]
  getActions _ _ _ = pure []

instance (TreacheryRunner env) => RunMessage env Chronophobia where
  runMessage msg t@(Chronophobia attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ unshiftMessage (AttachTreachery treacheryId $ InvestigatorTarget iid)
    EndTurn iid | InvestigatorTarget iid `elem` treacheryAttachedTarget ->
      t <$ unshiftMessage (InvestigatorDirectDamage iid (toSource attrs) 0 1)
    UseCardAbility _ (TreacherySource tid) _ 1 _ | tid == treacheryId ->
      t <$ unshiftMessage (Discard $ toTarget attrs)
    _ -> Chronophobia <$> runMessage msg attrs

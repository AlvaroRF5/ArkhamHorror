{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Treachery.Cards.Hypochondria
  ( Hypochondria(..)
  , hypochondria
  )
where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype Hypochondria = Hypochondria Attrs
  deriving newtype (Show, ToJSON, FromJSON)

hypochondria :: TreacheryId -> Maybe InvestigatorId -> Hypochondria
hypochondria uuid iid = Hypochondria $ weaknessAttrs uuid iid "01100"

instance HasModifiersFor env Hypochondria where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Hypochondria where
  getActions iid NonFast (Hypochondria a@Attrs {..}) =
    withTreacheryInvestigator a $ \tormented -> do
      treacheryLocation <- getId tormented
      investigatorLocationId <- getId @LocationId iid
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility (toSource a) 1 (ActionAbility Nothing $ ActionCost 2))
        | treacheryLocation == investigatorLocationId
        ]
  getActions _ _ _ = pure []

instance (TreacheryRunner env) => RunMessage env Hypochondria where
  runMessage msg t@(Hypochondria attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ unshiftMessage (AttachTreachery treacheryId $ InvestigatorTarget iid)
    After (InvestigatorTakeDamage iid _ n _)
      | treacheryOnInvestigator iid attrs && n > 0 -> t <$ unshiftMessage
        (InvestigatorDirectDamage iid (TreacherySource treacheryId) 0 1)
    UseCardAbility _ (TreacherySource tid) _ 1 | tid == treacheryId ->
      t <$ unshiftMessage (Discard (TreacheryTarget treacheryId))
    _ -> Hypochondria <$> runMessage msg attrs

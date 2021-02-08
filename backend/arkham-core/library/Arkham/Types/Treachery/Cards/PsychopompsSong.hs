module Arkham.Types.Treachery.Cards.PsychopompsSong
  ( psychopompsSong
  , PsychopompsSong(..)
  ) where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype PsychopompsSong = PsychopompsSong TreacheryAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

psychopompsSong :: TreacheryId -> a -> PsychopompsSong
psychopompsSong uuid _ = PsychopompsSong $ baseAttrs uuid "02221"

instance HasModifiersFor env PsychopompsSong where
  getModifiersFor = noModifiersFor

ability :: TreacheryAttrs -> Ability
ability attrs = mkAbility (toSource attrs) 1 ForcedAbility

instance HasActions env PsychopompsSong where
  getActions iid (WhenWouldTakeDamage _ (InvestigatorTarget iid')) (PsychopompsSong attrs)
    | treacheryOnInvestigator iid attrs && iid == iid'
    = pure [ActivateCardAbilityAction iid (ability attrs)]
  getActions i window (PsychopompsSong attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env PsychopompsSong where
  runMessage msg t@(PsychopompsSong attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ unshiftMessage (AttachTreachery treacheryId $ InvestigatorTarget iid)
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      mMsg <- findFromQueue $ \case
        InvestigatorDamage iid' _ n _ | iid' == iid -> n > 0
        InvestigatorDoAssignDamage iid' _ _ n _ [] [] | iid' == iid -> n > 0
        _ -> False
      _ <- error $ show mMsg
      case mMsg of
        Just damageMsg -> do
          let
            newMsg = case damageMsg of
              InvestigatorDamage _ source' n horror ->
                InvestigatorDamage iid source' (n + 2) horror
              InvestigatorDoAssignDamage _ source' strategy n horror [] [] ->
                InvestigatorDoAssignDamage
                  iid
                  source'
                  strategy
                  (n + 2)
                  horror
                  []
                  []
              _ -> error "impossible"
          t <$ replaceMessage damageMsg [newMsg, Discard (toTarget attrs)]
        Nothing -> throwIO $ InvalidState "No damage occured"
    _ -> PsychopompsSong <$> runMessage msg attrs

module Arkham.Types.Treachery.Cards.CryptChill where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype CryptChill = CryptChill Attrs
  deriving newtype (Show, ToJSON, FromJSON)

cryptChill :: TreacheryId -> a -> CryptChill
cryptChill uuid _ = CryptChill $ baseAttrs uuid "01167"

instance HasModifiersFor env CryptChill where
  getModifiersFor = noModifiersFor

instance HasActions env CryptChill where
  getActions i window (CryptChill attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env CryptChill where
  runMessage msg t@(CryptChill attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      t <$ unshiftMessages
        [ RevelationSkillTest iid source SkillWillpower 4
        , Discard (TreacheryTarget treacheryId)
        ]
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _
      | isSource attrs source -> do
        assetCount <- length <$> getSet @DiscardableAssetId iid
        if assetCount > 0
          then t <$ unshiftMessage (ChooseAndDiscardAsset iid)
          else t <$ unshiftMessage (InvestigatorAssignDamage iid source DamageAny 2 0)
    _ -> CryptChill <$> runMessage msg attrs

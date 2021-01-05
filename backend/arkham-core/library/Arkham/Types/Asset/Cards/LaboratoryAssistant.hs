module Arkham.Types.Asset.Cards.LaboratoryAssistant
  ( LaboratoryAssistant(..)
  , laboratoryAssistant
  )
where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner

newtype LaboratoryAssistant = LaboratoryAssistant Attrs
  deriving newtype (Show, ToJSON, FromJSON)

laboratoryAssistant :: AssetId -> LaboratoryAssistant
laboratoryAssistant uuid = LaboratoryAssistant $ (baseAttrs uuid "02020")
  { assetSlots = [AllySlot]
  , assetHealth = Just 1
  , assetSanity = Just 2
  }

instance HasModifiersFor env LaboratoryAssistant where
  getModifiersFor _ (InvestigatorTarget iid) (LaboratoryAssistant attrs) =
    pure $ toModifiers attrs [ HandSize 2 | ownedBy attrs iid ]
  getModifiersFor _ _ _ = pure []

instance HasActions env LaboratoryAssistant where
  getActions i window (LaboratoryAssistant x) = getActions i window x

instance (AssetRunner env) => RunMessage env LaboratoryAssistant where
  runMessage msg a@(LaboratoryAssistant attrs) = case msg of
    InvestigatorPlayAsset iid aid _ _ | aid == assetId attrs -> do
      unshiftMessage
        (chooseOne
          iid
          [ UseCardAbility iid (toSource attrs) Nothing 1
          , Continue "Do not use ability"
          ]
        )
      LaboratoryAssistant <$> runMessage msg attrs
    UseCardAbility iid source _ 1 | isSource attrs source ->
      a <$ unshiftMessage (DrawCards iid 2 False)
    _ -> LaboratoryAssistant <$> runMessage msg attrs

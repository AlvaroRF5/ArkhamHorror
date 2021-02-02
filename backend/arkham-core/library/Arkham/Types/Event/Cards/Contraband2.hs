module Arkham.Types.Event.Cards.Contraband2
  ( contraband2
  , Contraband2(..)
  ) where

import Arkham.Import

import Arkham.Types.Asset.Uses
import Arkham.Types.Event.Attrs

newtype Contraband2 = Contraband2 Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

contraband2 :: InvestigatorId -> EventId -> Contraband2
contraband2 iid uuid = Contraband2 $ baseAttrs iid uuid "02109"

instance HasActions env Contraband2 where
  getActions iid window (Contraband2 attrs) = getActions iid window attrs

instance HasModifiersFor env Contraband2 where
  getModifiersFor = noModifiersFor

instance
  ( HasQueue env
  , HasId LocationId env InvestigatorId
  , HasSet InvestigatorId env LocationId
  , HasSet AssetId env (InvestigatorId, UseType)
  , HasCount UsesCount env AssetId
  )
  => RunMessage env Contraband2 where
  runMessage msg e@(Contraband2 attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      locationId <- getId @LocationId iid
      investigatorIds <- getSetList @InvestigatorId locationId
      ammoAssets <- concat
        <$> for investigatorIds (getSetList @AssetId . (, Ammo))

      ammoAssetsWithUseCount <- map (\(c, aid) -> (Ammo, c, aid))
        <$> for ammoAssets (\aid -> (, aid) . unUsesCount <$> getCount aid)

      supplyAssets <- concat
        <$> for investigatorIds (getSetList @AssetId . (, Supply))

      supplyAssetsWithUseCount <- map (\(c, aid) -> (Supply, c, aid))
        <$> for supplyAssets (\aid -> (, aid) . unUsesCount <$> getCount aid)

      e <$ unshiftMessage
        (chooseOne
          iid
          [ Label
            "Place 2 ammo or supply tokens on that asset and draw 1 card."
            [ chooseOne
                iid
                [ TargetLabel
                    (AssetTarget assetId)
                    [ AddUses (AssetTarget assetId) useType' 2
                    , DrawCards iid 1 False
                    ]
                | (useType', _, assetId) <-
                  ammoAssetsWithUseCount <> supplyAssetsWithUseCount
                ]
            ]
          , Label
            "Double the number of ammo or supply tokens on that asset."
            [ chooseOne
                iid
                [ TargetLabel
                    (AssetTarget assetId)
                    [AddUses (AssetTarget assetId) useType' assetUseCount]
                | (useType', assetUseCount, assetId) <-
                  ammoAssetsWithUseCount <> supplyAssetsWithUseCount
                ]
            ]
          ]
        )
    _ -> Contraband2 <$> runMessage msg attrs

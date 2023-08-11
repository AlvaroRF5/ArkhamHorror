module Arkham.Event.Cards.Contraband (
  contraband,
  Contraband (..),
) where

import Arkham.Prelude

import Arkham.Asset.Types
import Arkham.Asset.Uses
import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection

newtype Contraband = Contraband EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

contraband :: EventCard Contraband
contraband = event Contraband Cards.contraband

instance RunMessage Contraband where
  runMessage msg e@(Contraband attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> do
      investigatorIds <-
        selectList $
          InvestigatorAt $
            LocationWithInvestigator $
              InvestigatorWithId iid

      ammoAssets <-
        selectList
          ( AssetWithUseType Ammo
              <> AssetNotAtUseLimit
              <> AssetOneOf
                (map (AssetControlledBy . InvestigatorWithId) investigatorIds)
          )

      ammoAssetsWithUseCount <-
        map (\(c, aid) -> (Ammo, c, aid))
          <$> for
            ammoAssets
            (\aid -> (,aid) . useCount <$> field AssetUses aid)

      supplyAssets <-
        selectList
          ( AssetWithUseType Supply
              <> AssetNotAtUseLimit
              <> AssetOneOf
                (map (AssetControlledBy . InvestigatorWithId) investigatorIds)
          )

      supplyAssetsWithUseCount <-
        map (\(c, aid) -> (Supply, c, aid))
          <$> for
            supplyAssets
            (\aid -> (,aid) . useCount <$> field AssetUses aid)

      e
        <$ pushAll
          [ chooseOne
              iid
              [ targetLabel
                assetId
                [AddUses assetId useType' assetUseCount]
              | (useType', assetUseCount, assetId) <-
                  ammoAssetsWithUseCount <> supplyAssetsWithUseCount
              ]
          ]
    _ -> Contraband <$> runMessage msg attrs

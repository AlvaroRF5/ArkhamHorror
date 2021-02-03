module Arkham.Types.Asset.Cards.BeatCop2
  ( BeatCop2(..)
  , beatCop2
  ) where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner

newtype BeatCop2 = BeatCop2 AssetAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

beatCop2 :: AssetId -> BeatCop2
beatCop2 uuid = BeatCop2 $ (baseAttrs uuid "01018")
  { assetSlots = [AllySlot]
  , assetHealth = Just 3
  , assetSanity = Just 2
  }

instance HasModifiersFor env BeatCop2 where
  getModifiersFor _ (InvestigatorTarget iid) (BeatCop2 a) =
    pure [ toModifier a (SkillModifier SkillCombat 1) | ownedBy a iid ]
  getModifiersFor _ _ _ = pure []

ability :: AssetAttrs -> Ability
ability a = mkAbility
  (toSource a)
  1
  (FastAbility
  $ Costs [ExhaustCost (toTarget a), DamageCost (toSource a) (toTarget a) 1]
  )

instance HasActions env BeatCop2 where
  getActions iid _ (BeatCop2 a) | ownedBy a iid =
    pure [ActivateCardAbilityAction iid (ability a)]
  getActions _ _ _ = pure []

instance (AssetRunner env) => RunMessage env BeatCop2 where
  runMessage msg a@(BeatCop2 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      locationId <- getId @LocationId (getInvestigator attrs)
      locationEnemyIds <- getSetList locationId
      a <$ unshiftMessage
        (chooseOne
          iid
          [ EnemyDamage eid iid (toSource attrs) 1 | eid <- locationEnemyIds ]
        )
    _ -> BeatCop2 <$> runMessage msg attrs

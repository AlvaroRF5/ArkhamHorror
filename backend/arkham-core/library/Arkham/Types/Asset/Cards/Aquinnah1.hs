module Arkham.Types.Asset.Cards.Aquinnah1
  ( Aquinnah1(..)
  , aquinnah1
  )
where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner

newtype Aquinnah1 = Aquinnah1 AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

aquinnah1 :: AssetId -> Aquinnah1
aquinnah1 uuid = Aquinnah1 $ (baseAttrs uuid "01082")
  { assetSlots = [AllySlot]
  , assetHealth = Just 1
  , assetSanity = Just 4
  }

reactionAbility :: AssetAttrs -> Ability
reactionAbility attrs = mkAbility
  (toSource attrs)
  1
  (FastAbility $ Costs
    [ ExhaustCost (toTarget attrs)
    , HorrorCost (toSource attrs) (toTarget attrs) 1
    ]
  )

dropUntilAttack :: [Message] -> [Message]
dropUntilAttack = dropWhile (notElem AttackMessage . messageType)

instance HasModifiersFor env Aquinnah1 where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Aquinnah1 where
  getActions iid (WhenEnemyAttacks You) (Aquinnah1 a) | ownedBy a iid = do
    locationId <- getId @LocationId iid
    enemyId <- fromQueue $ \queue ->
      let PerformEnemyAttack iid' eid : _ = dropUntilAttack queue
      in if iid' == iid then eid else error "mismatch"
    enemyIds <- filterSet (/= enemyId) <$> getSet locationId
    pure
      [ ActivateCardAbilityAction iid (reactionAbility a)
      | not (null enemyIds)
      ]
  getActions i window (Aquinnah1 x) = getActions i window x

instance AssetRunner env => RunMessage env Aquinnah1 where
  runMessage msg a@(Aquinnah1 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      enemyId <- withQueue $ \queue ->
        let PerformEnemyAttack _ eid : queue' = dropUntilAttack queue
        in (queue', eid)
      healthDamage' <- unHealthDamageCount <$> getCount enemyId
      sanityDamage' <- unSanityDamageCount <$> getCount enemyId
      locationId <- getId @LocationId iid
      enemyIds <- filter (/= enemyId) <$> getSetList locationId

      when (null enemyIds) (error "other enemies had to be present")

      a <$ unshiftMessage
        (chooseOne
          iid
          [ Run
              [ EnemyDamage eid iid source healthDamage'
              , InvestigatorAssignDamage
                iid
                (EnemySource enemyId)
                DamageAny
                0
                sanityDamage'
              ]
          | eid <- enemyIds
          ]
        )
    _ -> Aquinnah1 <$> runMessage msg attrs

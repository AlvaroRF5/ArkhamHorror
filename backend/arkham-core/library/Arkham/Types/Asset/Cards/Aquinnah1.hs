module Arkham.Types.Asset.Cards.Aquinnah1
  ( Aquinnah1(..)
  , aquinnah1
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Id
import Arkham.Types.Matcher
import Arkham.Types.Message hiding (EnemyAttacks)
import Arkham.Types.Query
import Arkham.Types.Source
import qualified Arkham.Types.Timing as Timing

newtype Aquinnah1 = Aquinnah1 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

aquinnah1 :: AssetCard Aquinnah1
aquinnah1 = ally Aquinnah1 Cards.aquinnah1 (1, 4)

dropUntilAttack :: [Message] -> [Message]
dropUntilAttack = dropWhile (notElem AttackMessage . messageType)

instance HasAbilities env Aquinnah1 where
  getAbilities _ _ (Aquinnah1 a) = pure
    [ restrictedAbility
        a
        1
        (OwnsThis <> EnemyCriteria
          (NotAttackingEnemy <> EnemyExists (EnemyAt YourLocation))
        )
      $ ReactionAbility (EnemyAttacks Timing.When You AnyEnemy)
      $ Costs [ExhaustCost (toTarget a), HorrorCost (toSource a) (toTarget a) 1]
    ]

instance AssetRunner env => RunMessage env Aquinnah1 where
  runMessage msg a@(Aquinnah1 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      enemyId <- withQueue $ \queue ->
        let PerformEnemyAttack _ eid _ : queue' = dropUntilAttack queue
        in (queue', eid)
      healthDamage' <- unHealthDamageCount <$> getCount enemyId
      sanityDamage' <- unSanityDamageCount <$> getCount enemyId
      locationId <- getId @LocationId iid
      enemyIds <- filter (/= enemyId) <$> getSetList locationId

      when (null enemyIds) (error "other enemies had to be present")

      a <$ push
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

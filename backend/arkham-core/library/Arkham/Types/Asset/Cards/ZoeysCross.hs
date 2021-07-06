module Arkham.Types.Asset.Cards.ZoeysCross
  ( ZoeysCross(..)
  , zoeysCross
  )
where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.EnemyId
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Window

newtype ZoeysCross = ZoeysCross AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

zoeysCross :: AssetCard ZoeysCross
zoeysCross = accessory ZoeysCross Cards.zoeysCross

instance HasModifiersFor env ZoeysCross where
  getModifiersFor = noModifiersFor

ability :: AssetAttrs -> EnemyId -> Ability
ability attrs eid = base
  { abilityMetadata = Just (TargetMetadata (EnemyTarget eid))
  }
 where
  base = mkAbility
    (toSource attrs)
    1
    (ReactionAbility $ Costs [ExhaustCost (toTarget attrs), ResourceCost 1])

instance HasActions env ZoeysCross where
  getActions iid (AfterEnemyEngageInvestigator You eid) (ZoeysCross a)
    | ownedBy a iid = pure [UseAbility iid (ability a eid)]
  getActions i window (ZoeysCross x) = getActions i window x

instance (AssetRunner env) => RunMessage env ZoeysCross where
  runMessage msg a@(ZoeysCross attrs) = case msg of
    UseCardAbility iid source (Just (TargetMetadata (EnemyTarget eid))) 1 _
      | isSource attrs source -> a <$ push (EnemyDamage eid iid source 1)
    _ -> ZoeysCross <$> runMessage msg attrs

module Arkham.Types.Asset.Cards.LitaChantler where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.Window

newtype LitaChantler = LitaChantler AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

litaChantler :: AssetCard LitaChantler
litaChantler =
  allyWith LitaChantler Cards.litaChantler (3, 3) (isStoryL .~ True)

instance HasId LocationId env InvestigatorId => HasModifiersFor env LitaChantler where
  getModifiersFor _ (InvestigatorTarget iid) (LitaChantler a@AssetAttrs {..}) =
    do
      locationId <- getId @LocationId iid
      case assetInvestigator of
        Nothing -> pure []
        Just ownerId -> do
          sameLocation <- (== locationId) <$> getId ownerId
          pure [ toModifier a (SkillModifier SkillCombat 1) | sameLocation ]
  getModifiersFor _ _ _ = pure []

ability :: EnemyId -> AssetAttrs -> Ability
ability eid a = (mkAbility (toSource a) 1 (ReactionAbility Free))
  { abilityMetadata = Just $ TargetMetadata (EnemyTarget eid)
  }

instance
  ( HasId LocationId env InvestigatorId
  , HasSet Trait env EnemyId
  )
  => HasActions env LitaChantler where
  getActions i (WhenSuccessfulAttackEnemy who eid) (LitaChantler a)
    | ownedBy a i = do
      atYourLocation <- liftA2
        (==)
        (getId @LocationId i)
        (getId @LocationId who)
      traits <- getSetList eid
      pure
        [ UseAbility i (ability eid a)
        | Monster `elem` traits && atYourLocation
        ]
  getActions i window (LitaChantler a) = getActions i window a

instance (AssetRunner env) => RunMessage env LitaChantler where
  runMessage msg a@(LitaChantler attrs) = case msg of
    UseCardAbility _ source (Just (TargetMetadata target)) 1 _
      | isSource attrs source -> do
        a <$ push (skillTestModifier attrs target (DamageTaken 1))
    _ -> LitaChantler <$> runMessage msg attrs


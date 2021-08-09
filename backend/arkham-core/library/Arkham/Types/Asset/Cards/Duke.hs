module Arkham.Types.Asset.Cards.Duke
  ( Duke(..)
  , duke
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Window

newtype Duke = Duke AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

duke :: AssetCard Duke
duke = allyWith Duke Cards.duke (2, 3) (slotsL .~ mempty)

instance HasModifiersFor env Duke where
  getModifiersFor (SkillTestSource _ _ source _ (Just Action.Fight)) (InvestigatorTarget iid) (Duke a)
    | ownedBy a iid && isSource a source
    = pure $ toModifiers a [BaseSkillOf SkillCombat 4, DamageDealt 1]
  getModifiersFor (SkillTestSource _ _ source _ (Just Action.Investigate)) (InvestigatorTarget iid) (Duke a)
    | ownedBy a iid && isSource a source
    = pure $ toModifiers a [BaseSkillOf SkillIntellect 4]
  getModifiersFor _ _ _ = pure []

fightAbility :: AssetAttrs -> Ability
fightAbility attrs = mkAbility
  (toSource attrs)
  1
  (ActionAbility
    (Just Action.Fight)
    (Costs [ActionCost 1, ExhaustCost (toTarget attrs)])
  )

investigateAbility :: AssetAttrs -> Ability
investigateAbility attrs = mkAbility
  (toSource attrs)
  2
  (ActionAbilityWithBefore
    (Just Action.Investigate)
    (Just Action.Move)
    (Costs [ActionCost 1, ExhaustCost (toTarget attrs)])
  )

instance HasActions env Duke where
  getActions iid NonFast (Duke a) | ownedBy a iid =
    pure [fightAbility a, investigateAbility a]
  getActions i window (Duke x) = getActions i window x

dukeInvestigate :: AssetAttrs -> InvestigatorId -> LocationId -> Message
dukeInvestigate attrs iid lid =
  Investigate iid lid (toSource attrs) SkillIntellect False

isInvestigate :: Ability -> Bool
isInvestigate ability = case abilityType ability of
  ActionAbility (Just Action.Investigate) _ -> True
  ActionAbilityWithBefore (Just Action.Investigate) _ _ -> True
  ActionAbilityWithBefore _ (Just Action.Investigate) _ -> True
  _ -> False

instance AssetRunner env => RunMessage env Duke where
  runMessage msg a@(Duke attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      a <$ push (ChooseFightEnemy iid source SkillCombat mempty False)
    UseCardAbility iid source _ 2 _ | isSource attrs source -> do
      lid <- getId @LocationId iid
      investigateAbilities :: [Ability] <-
        filterM
            (\a' -> liftA2
              (&&)
              (pure $ isInvestigate a')
              (getCanAffordAbility iid a')
            )
          =<< getActions iid NonFast lid
      let
        investigateActions :: [Message] = map
          (UseAbility iid . (`applyAbilityModifiers` [ActionCostModifier (-1)]))
          investigateAbilities
      accessibleLocationIds <- map unAccessibleLocationId <$> getSetList lid
      a <$ if null accessibleLocationIds
        then pushAll investigateActions
        else push
          (chooseOne iid
          $ investigateActions
          <> [ Run
                 [ MoveAction iid lid' Free False
                 , CheckAdditionalActionCosts
                   iid
                   (LocationTarget lid')
                   (toSource attrs)
                   Action.Investigate
                   [dukeInvestigate attrs iid lid']
                 ]
             | lid' <- accessibleLocationIds
             ]
          )
    _ -> Duke <$> runMessage msg attrs

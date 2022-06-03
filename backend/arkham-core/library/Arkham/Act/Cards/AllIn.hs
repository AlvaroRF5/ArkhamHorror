module Arkham.Act.Cards.AllIn
  ( AllIn(..)
  , allIn
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Attrs
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Helpers
import Arkham.Act.Runner
import Arkham.Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Card
import Arkham.Classes
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import Arkham.Query
import Arkham.Resolution
import Arkham.SkillType
import Arkham.Source
import Arkham.Target

newtype AllIn = AllIn ActAttrs
  deriving anyclass (IsAct, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

allIn :: ActCard AllIn
allIn = act (3, A) AllIn Cards.allIn Nothing

instance HasAbilities AllIn where
  getAbilities (AllIn x) = withBaseAbilities x $ if onSide A x
    then
      [ restrictedAbility
        (ProxySource
          (AssetMatcherSource $ assetIs Cards.drFrancisMorgan)
          (toSource x)
        )
        1
        (Unowned <> OnSameLocation)
        (ActionAbility (Just Parley) $ ActionCost 1)
      , restrictedAbility x 1 AllUndefeatedInvestigatorsResigned
      $ Objective
      $ ForcedAbility AnyWindow
      ]
    else []

instance ActRunner env => RunMessage AllIn where
  runMessage msg a@(AllIn attrs@ActAttrs {..}) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AdvanceAct (toId attrs) source AdvancedWithOther)
    AdvanceAct aid _ _ | aid == actId && onSide B attrs -> do
      resignedWithDrFrancisMorgan <- elem (ResignedCardCode $ CardCode "02080")
        <$> getList ()
      let resolution = if resignedWithDrFrancisMorgan then 2 else 1
      a <$ push (ScenarioResolution $ Resolution resolution)
    UseCardAbility iid (ProxySource _ source) _ 1 _
      | isSource attrs source && onSide A attrs -> do
        maid <- selectOne (assetIs Cards.drFrancisMorgan)
        case maid of
          Nothing -> error "this ability should not be able to be used"
          Just aid -> a <$ push
            (BeginSkillTest
              iid
              source
              (AssetTarget aid)
              (Just Parley)
              SkillWillpower
              3
            )
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source && onSide A attrs -> do
        maid <- selectOne (assetIs Cards.drFrancisMorgan)
        case maid of
          Nothing -> error "this ability should not be able to be used"
          Just aid -> do
            currentClueCount <- unClueCount <$> getCount aid
            requiredClueCount <- getPlayerCountValue (PerPlayer 1)
            push (PlaceClues (AssetTarget aid) 1)
            a <$ when
              (currentClueCount + 1 >= requiredClueCount)
              (push $ TakeControlOfAsset iid aid)
    _ -> AllIn <$> runMessage msg attrs

module Arkham.Types.Asset.Cards.LiquidCourage
  ( liquidCourage
  , LiquidCourage(..)
  )
where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Uses

newtype LiquidCourage = LiquidCourage Attrs
  deriving newtype (Show, ToJSON, FromJSON)

liquidCourage :: AssetId -> LiquidCourage
liquidCourage uuid = LiquidCourage $ baseAttrs uuid "02024"

instance HasActions env LiquidCourage where
  getActions iid NonFast (LiquidCourage a) = pure
    [ ActivateCardAbilityAction
        iid
        (mkAbility
          (toSource a)
          1
          (ActionAbility Nothing
          $ Costs [ActionCost 1, UseCost (toId a) Supply 1]
          )
        )
    | ownedBy a iid
    ]
  getActions iid window (LiquidCourage attrs) = getActions iid window attrs

instance HasModifiersFor env LiquidCourage where
  getModifiersFor = noModifiersFor

instance
  ( HasQueue env
  , HasModifiersFor env ()
  , HasSet InvestigatorId env LocationId
  , HasId LocationId env InvestigatorId
  )
  => RunMessage env LiquidCourage where
  runMessage msg a@(LiquidCourage attrs) = case msg of
    InvestigatorPlayAsset _ aid _ _ | aid == assetId attrs ->
      LiquidCourage <$> runMessage msg (attrs & usesL .~ Uses Supply 4)
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      lid <- getId @LocationId iid
      iids <- getSetList @InvestigatorId lid
      let
        abilityEffect iid' =
          [ HealHorror (InvestigatorTarget iid') 1
          , BeginSkillTest
            iid'
            source
            (InvestigatorTarget iid')
            Nothing
            SkillWillpower
            2
          ]
      a <$ case iids of
        [] -> pure ()
        [iid'] -> unshiftMessages $ abilityEffect iid'
        _ -> unshiftMessage
          (chooseOne
            iid
            [ TargetLabel (InvestigatorTarget iid') (abilityEffect iid')
            | iid' <- iids
            ]
          )
    PassedSkillTest iid _ source _ _ _ | isSource attrs source ->
      a <$ unshiftMessage (HealHorror (InvestigatorTarget iid) 1)
    FailedSkillTest iid _ source _ _ _ | isSource attrs source ->
      a <$ unshiftMessage (RandomDiscard iid)
    _ -> LiquidCourage <$> runMessage msg attrs

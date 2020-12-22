{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.LockedDoor where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner

newtype LockedDoor = LockedDoor Attrs
  deriving newtype (Show, ToJSON, FromJSON)

lockedDoor :: TreacheryId -> a -> LockedDoor
lockedDoor uuid _ = LockedDoor $ baseAttrs uuid "01174"

instance HasModifiersFor env LockedDoor where
  getModifiersFor _ (LocationTarget lid) (LockedDoor attrs) =
    pure $ toModifiers
      attrs
      [ CannotInvestigate | treacheryOnLocation lid attrs ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env LockedDoor where
  getActions iid NonFast (LockedDoor a@Attrs {..}) = do
    investigatorLocationId <- getId @LocationId iid
    canAffordActions <- getCanAffordCost
      iid
      (toSource a)
      (ActionCost 1 Nothing treacheryTraits)
    pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility (TreacherySource treacheryId) 1 (ActionAbility 1 Nothing))
      | treacheryOnLocation investigatorLocationId a && canAffordActions
      ]
  getActions _ _ _ = pure []

instance (TreacheryRunner env) => RunMessage env LockedDoor where
  runMessage msg t@(LockedDoor attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      exemptLocations <- getSet @LocationId
        (TreacheryCardCode treacheryCardCode)
      targetLocations <-
        setToList . (`difference` exemptLocations) <$> getSet @LocationId ()
      locations <- for
        targetLocations
        (traverseToSnd $ (unClueCount <$>) . getCount)
      case maxes locations of
        [] -> pure ()
        [x] -> unshiftMessages [AttachTreachery treacheryId (LocationTarget x)]
        xs -> unshiftMessage
          (chooseOne
            iid
            [ AttachTreachery treacheryId (LocationTarget x) | x <- xs ]
          )
      LockedDoor <$> runMessage msg attrs
    UseCardAbility iid (TreacherySource tid) _ 1 | tid == treacheryId -> do
      t <$ unshiftMessage
        (chooseOne
          iid
          [ BeginSkillTest
            iid
            (toSource attrs)
            (toTarget attrs)
            Nothing
            SkillCombat
            4
          , BeginSkillTest
            iid
            (toSource attrs)
            (toTarget attrs)
            Nothing
            SkillAgility
            4
          ]
        )
    PassedSkillTest _ _ source _ _ | isSource attrs source ->
      t <$ unshiftMessage (Discard $ toTarget attrs)
    _ -> LockedDoor <$> runMessage msg attrs

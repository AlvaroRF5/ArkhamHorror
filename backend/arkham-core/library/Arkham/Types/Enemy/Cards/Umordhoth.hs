{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Enemy.Cards.Umordhoth
  ( Umordhoth(..)
  , umordhoth
  )
where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Helpers
import Arkham.Types.Enemy.Runner

newtype Umordhoth = Umordhoth Attrs
  deriving newtype (Show, ToJSON, FromJSON)

umordhoth :: EnemyId -> Umordhoth
umordhoth uuid =
  Umordhoth
    $ baseAttrs uuid "01157"
    $ (healthDamageL .~ 3)
    . (sanityDamageL .~ 3)
    . (fightL .~ 5)
    . (healthL .~ Static 6)
    . (evadeL .~ 6)
    . (uniqueL .~ True)

instance HasModifiersFor env Umordhoth where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Umordhoth where
  getActions iid NonFast (Umordhoth attrs@Attrs {..}) =
    withBaseActions iid NonFast attrs $ do
      maid <- fmap unStoryAssetId <$> getId (CardCode "01117")
      locationId <- getId @LocationId iid
      case maid of
        Nothing -> pure []
        Just aid -> do
          miid <- fmap unOwnerId <$> getId aid
          pure
            [ ActivateCardAbilityAction
                iid
                (mkAbility
                  (EnemySource enemyId)
                  1
                  (ActionAbility Nothing $ ActionCost 1)
                )
            | locationId == enemyLocation && miid == Just iid
            ]
  getActions i window (Umordhoth attrs) = getActions i window attrs

instance (EnemyRunner env) => RunMessage env Umordhoth where
  runMessage msg e@(Umordhoth attrs@Attrs {..}) = case msg of
    EnemySpawn _ _ eid | eid == enemyId -> do
      playerCount <- unPlayerCount <$> getCount ()
      Umordhoth
        <$> runMessage msg (attrs & healthL %~ fmap (+ (4 * playerCount)))
    ChooseEndTurn _ ->
      Umordhoth <$> runMessage msg (attrs & exhaustedL .~ False)
    UseCardAbility _ (EnemySource eid) _ 1 | eid == enemyId ->
      e <$ unshiftMessage (Resolution 3)
    _ -> Umordhoth <$> runMessage msg attrs

module Arkham.Types.Treachery.Cards.AlteredBeast
  ( AlteredBeast(..)
  , alteredBeast
  )
where

import Arkham.Import

import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype AlteredBeast = AlteredBeast TreacheryAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

alteredBeast :: TreacheryId -> a -> AlteredBeast
alteredBeast uuid _ = AlteredBeast $ baseAttrs uuid "02096"

instance HasModifiersFor env AlteredBeast where
  getModifiersFor = noModifiersFor

instance HasActions env AlteredBeast where
  getActions i window (AlteredBeast attrs) = getActions i window attrs

instance (TreacheryRunner env) => RunMessage env AlteredBeast where
  runMessage msg t@(AlteredBeast attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      abominations <- getSetList @EnemyId Abomination
      t <$ case abominations of
        [] -> unshiftMessages [Surge iid source, Discard $ toTarget attrs]
        [x] -> unshiftMessages
          [ AttachTreachery treacheryId (EnemyTarget x)
          , HealAllDamage (EnemyTarget x)
          ]
        xs -> unshiftMessage
          (chooseOne
            iid
            [ TargetLabel
                (EnemyTarget x)
                [ AttachTreachery treacheryId (EnemyTarget x)
                , HealAllDamage (EnemyTarget x)
                ]
            | x <- xs
            ]
          )
    MoveTo iid lid -> case treacheryAttachedTarget of
      Just (EnemyTarget eid) -> do
        lid' <- getId @LocationId eid
        if lid == lid'
          then
            t <$ unshiftMessage
              (InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 1)
          else pure t
      _ -> pure t
    EnemyMove eid _ lid | EnemyTarget eid `elem` treacheryAttachedTarget -> do
      iids <- getSetList @InvestigatorId lid
      t <$ unshiftMessages
        [ InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 1 | iid <- iids ]
    _ -> AlteredBeast <$> runMessage msg attrs

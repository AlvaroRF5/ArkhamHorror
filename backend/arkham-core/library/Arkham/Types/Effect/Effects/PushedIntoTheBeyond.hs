module Arkham.Types.Effect.Effects.PushedIntoTheBeyond
  ( PushedIntoTheBeyond(..)
  , pushedIntoTheBeyond
  )
where

import Arkham.Import

import Arkham.Types.Effect.Attrs

newtype PushedIntoTheBeyond = PushedIntoTheBeyond Attrs
  deriving newtype (Show, ToJSON, FromJSON)

pushedIntoTheBeyond :: EffectArgs -> PushedIntoTheBeyond
pushedIntoTheBeyond = PushedIntoTheBeyond . uncurry4 (baseAttrs "02100")

instance HasModifiersFor env PushedIntoTheBeyond where
  getModifiersFor = noModifiersFor

instance HasQueue env => RunMessage env PushedIntoTheBeyond where
  runMessage msg e@(PushedIntoTheBeyond attrs@Attrs {..}) = case msg of
    CreatedEffect eid _ _ (InvestigatorTarget iid) | eid == effectId ->
      e <$ unshiftMessage (DiscardTopOfDeck iid 3 (Just $ EffectTarget eid))
    DiscardedTopOfDeck iid cards (EffectTarget eid) | eid == effectId ->
      case effectMetadata of
        Just (EffectCardCode x) -> e <$ when
          (x `elem` map pcCardCode cards)
          (unshiftMessage (InvestigatorAssignDamage iid effectSource 0 2))
        _ -> throwIO (InvalidState "Must have one card as the target")
    _ -> PushedIntoTheBeyond <$> runMessage msg attrs

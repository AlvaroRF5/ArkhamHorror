module Arkham.Types.Effect.Effects.Burglary
  ( burglary
  , Burglary(..)
  )
where

import Arkham.Import

import Arkham.Types.Effect.Attrs
import Arkham.Types.Effect.Helpers

newtype Burglary = Burglary Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

burglary :: EffectArgs -> Burglary
burglary = Burglary . uncurry4 (baseAttrs "01045")

instance HasModifiersFor env Burglary where
  getModifiersFor _ (LocationTarget lid) (Burglary attrs@Attrs {..}) =
    case effectTarget of
      InvestigationTarget _ lid' | lid == lid' ->
        pure [toModifier attrs AlternateSuccessfullInvestigation]
      _ -> pure []
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env Burglary where
  runMessage msg e@(Burglary attrs@Attrs {..}) = case msg of
    CreatedEffect eid _ _ (InvestigationTarget iid lid) | eid == effectId ->
      e <$ unshiftMessage
        (Investigate iid lid (toSource attrs) SkillIntellect False)
    SuccessfulInvestigation iid _ source | isSource attrs source ->
      e <$ unshiftMessages [TakeResources iid 3 False, DisableEffect effectId]
    SkillTestEnds _ -> e <$ unshiftMessage (DisableEffect effectId)
    _ -> Burglary <$> runMessage msg attrs

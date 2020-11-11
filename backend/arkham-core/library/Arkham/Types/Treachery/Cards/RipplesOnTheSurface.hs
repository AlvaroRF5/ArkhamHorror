{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.RipplesOnTheSurface
  ( RipplesOnTheSurface(..)
  , ripplesOnTheSurface
  )
where

import Arkham.Import

import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype RipplesOnTheSurface = RipplesOnTheSurface Attrs
  deriving newtype (Show, ToJSON, FromJSON)

ripplesOnTheSurface :: TreacheryId -> a -> RipplesOnTheSurface
ripplesOnTheSurface uuid _ = RipplesOnTheSurface $ baseAttrs uuid "81027"

instance HasModifiersFor env RipplesOnTheSurface where
  getModifiersFor = noModifiersFor

instance HasActions env RipplesOnTheSurface where
  getActions i window (RipplesOnTheSurface attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env RipplesOnTheSurface where
  runMessage msg t@(RipplesOnTheSurface attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      locationId <- asks $ getId @LocationId iid
      isBayou <- asks $ member Bayou . getSet locationId
      unshiftMessages
        [ RevelationSkillTest
          iid
          source
          SkillWillpower
          3
          []
          []
          [ CannotCommitCards | isBayou ]
        , Discard (TreacheryTarget treacheryId)
        ]
      RipplesOnTheSurface <$> runMessage msg (attrs & resolved .~ True)
    FailedSkillTest iid _ (TreacherySource tid) SkillTestInitiatorTarget n
      | tid == treacheryId -> t <$ unshiftMessage
        (InvestigatorAssignDamage iid (TreacherySource treacheryId) 0 n)
    _ -> RipplesOnTheSurface <$> runMessage msg attrs

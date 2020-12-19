{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.LightOfAforgomon
  ( LightOfAforgomon(..)
  , lightOfAforgomon
  )
where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype LightOfAforgomon = LightOfAforgomon Attrs
  deriving newtype (Show, ToJSON, FromJSON)

lightOfAforgomon :: TreacheryId -> a -> LightOfAforgomon
lightOfAforgomon uuid _ = LightOfAforgomon $ baseAttrs uuid "02085"

instance HasModifiersFor env LightOfAforgomon where
  getModifiersFor _ (InvestigatorTarget _) (LightOfAforgomon _) =
    pure [TreatAllDamageAsDirect]
  getModifiersFor _ _ _ = pure []

instance HasActions env LightOfAforgomon where
  getActions i window (LightOfAforgomon attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env LightOfAforgomon where
  runMessage msg (LightOfAforgomon attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      exemptActs <- getSet (TreacheryCardCode $ CardCode "81025")
      exemptAgendas <- getSet (TreacheryCardCode $ CardCode "81025")
      targetActs <-
        map ActTarget . setToList . (`difference` exemptActs) <$> getSet ()
      targetAgendas <-
        map AgendaTarget
        . setToList
        . (`difference` exemptAgendas)
        <$> getSet ()
      if null (targetActs <> targetAgendas)
        then unshiftMessage (Discard $ toTarget attrs)
        else unshiftMessage $ chooseOne
          iid
          [ AttachTreachery treacheryId target
          | target <- targetActs <> targetAgendas
          ]
      LightOfAforgomon <$> runMessage msg attrs
    _ -> LightOfAforgomon <$> runMessage msg attrs

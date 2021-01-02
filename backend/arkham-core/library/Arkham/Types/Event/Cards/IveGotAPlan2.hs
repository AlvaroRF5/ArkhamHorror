{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event.Cards.IveGotAPlan2
  ( iveGotAPlan2
  , IveGotAPlan2(..)
  )
where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Helpers

newtype IveGotAPlan2 = IveGotAPlan2 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

iveGotAPlan2 :: InvestigatorId -> EventId -> IveGotAPlan2
iveGotAPlan2 iid uuid =
  IveGotAPlan2 $ baseAttrs iid uuid "60225"

instance HasActions env IveGotAPlan2 where
  getActions iid window (IveGotAPlan2 attrs) = getActions iid window attrs

instance (HasCount ClueCount env InvestigatorId) => HasModifiersFor env IveGotAPlan2 where
  getModifiersFor (SkillTestSource iid _ _ (Just Fight)) (InvestigatorTarget _) (IveGotAPlan2 attrs) = do
    clueCount <- unClueCount <$> getCount iid
    pure $ modifiers attrs [ DamageDealt (min clueCount 3), SkillModifier SkillIntellect 2 ]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env IveGotAPlan2 where
  runMessage msg e@(IveGotAPlan2 attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      e <$ unshiftMessage (ChooseFightEnemy iid (EventSource eid) SkillIntellect False)
    _ -> IveGotAPlan2 <$> runMessage msg attrs

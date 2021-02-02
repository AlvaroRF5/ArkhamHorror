module Arkham.Types.Event.Cards.Shortcut
  ( shortcut
  , Shortcut(..)
  )
where

import Arkham.Import

import Arkham.Types.Event.Attrs

newtype Shortcut = Shortcut Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

shortcut :: InvestigatorId -> EventId -> Shortcut
shortcut iid uuid = Shortcut $ baseAttrs iid uuid "02022"

instance HasActions env Shortcut where
  getActions iid window (Shortcut attrs) = getActions iid window attrs

instance HasModifiersFor env Shortcut where
  getModifiersFor = noModifiersFor

instance
  ( HasQueue env
  , HasSet AccessibleLocationId env LocationId
  , HasSet InvestigatorId env LocationId
  , HasId LocationId env InvestigatorId
  )
  => RunMessage env Shortcut where
  runMessage msg e@(Shortcut attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      lid <- getId @LocationId iid
      investigatorIds <- getSetList lid
      connectingLocations <- map unAccessibleLocationId <$> getSetList lid
      e <$ unshiftMessages
        [ chooseOne
          iid
          [ TargetLabel
              (InvestigatorTarget iid')
              [ chooseOne
                  iid
                  [ TargetLabel (LocationTarget lid') [Move iid' lid lid']
                  | lid' <- connectingLocations
                  ]
              ]
          | iid' <- investigatorIds
          ]
        , Discard (toTarget attrs)
        ]
    _ -> Shortcut <$> runMessage msg attrs

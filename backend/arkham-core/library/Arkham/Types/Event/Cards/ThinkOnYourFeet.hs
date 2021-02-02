module Arkham.Types.Event.Cards.ThinkOnYourFeet
  ( thinkOnYourFeet
  , ThinkOnYourFeet(..)
  )
where

import Arkham.Import

import Arkham.Types.Event.Attrs

newtype ThinkOnYourFeet = ThinkOnYourFeet Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

thinkOnYourFeet :: InvestigatorId -> EventId -> ThinkOnYourFeet
thinkOnYourFeet iid uuid = ThinkOnYourFeet $ baseAttrs iid uuid "02025"

instance HasActions env ThinkOnYourFeet where
  getActions iid window (ThinkOnYourFeet attrs) = getActions iid window attrs

instance HasModifiersFor env ThinkOnYourFeet where
  getModifiersFor = noModifiersFor

instance
  ( HasQueue env
  , HasSet AccessibleLocationId env LocationId
  , HasId LocationId env InvestigatorId
  )
  => RunMessage env ThinkOnYourFeet where
  runMessage msg e@(ThinkOnYourFeet attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      lid <- getId @LocationId iid
      connectedLocationIds <- map unAccessibleLocationId <$> getSetList lid
      e <$ unshiftMessages
        [ chooseOne
          iid
          [ TargetLabel (LocationTarget lid') [Move iid lid lid']
          | lid' <- connectedLocationIds
          ]
        , Discard (toTarget attrs)
        ]
    _ -> ThinkOnYourFeet <$> runMessage msg attrs

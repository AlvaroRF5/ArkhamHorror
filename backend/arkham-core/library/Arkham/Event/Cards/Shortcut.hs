module Arkham.Event.Cards.Shortcut
  ( shortcut
  , Shortcut(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Attrs
import Arkham.Event.Cards qualified as Cards
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Target

newtype Shortcut = Shortcut EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

shortcut :: EventCard Shortcut
shortcut = event Shortcut Cards.shortcut

instance RunMessage Shortcut where
  runMessage msg e@(Shortcut attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> do
      let discard = Discard $ toTarget attrs
      mlid <- field InvestigatorLocation iid
      case mlid of
        Just lid -> do
          investigatorIds <- selectList $ colocatedWith iid
          connectingLocations <- selectList AccessibleLocation
          if null connectingLocations
            then push discard
            else pushAll
              [ chooseOne
                iid
                [ TargetLabel
                    (InvestigatorTarget iid')
                    [ chooseOne
                        iid
                        [ TargetLabel
                            (LocationTarget lid')
                            [Move (toSource attrs) iid' lid lid']
                        | lid' <- connectingLocations
                        ]
                    ]
                | iid' <- investigatorIds
                ]
              , discard
              ]
        Nothing -> push discard
      pure e
    _ -> Shortcut <$> runMessage msg attrs

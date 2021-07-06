module Arkham.Types.Event.Cards.BloodRite
  ( bloodRite
  , BloodRite(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Source

newtype BloodRite = BloodRite EventAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

bloodRite :: EventCard BloodRite
bloodRite = event BloodRite Cards.bloodRite

instance HasModifiersFor env BloodRite where
  getModifiersFor = noModifiersFor

instance HasActions env BloodRite where
  getActions i window (BloodRite attrs) = getActions i window attrs

instance EventRunner env => RunMessage env BloodRite where
  runMessage msg e@(BloodRite attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> e <$ pushAll
      [ DrawCards iid 2 False
      , PayForCardAbility iid (EventSource eid) (Just $ IntMetadata 0) 1
      , Discard (toTarget attrs)
      ]
    PayForCardAbility iid source meta@(Just (IntMetadata n)) 1
      | isSource attrs source -> if n == 2
        then e <$ push (UseCardAbility iid source meta 1 NoPayment)
        else do
          cards <- map unDiscardableHandCard <$> getList iid
          e <$ push
            (chooseOne iid
            $ [ Run
                  [ DiscardCard iid (toCardId card)
                  , PayForCardAbility
                    iid
                    source
                    (Just (IntMetadata $ n + 1))
                    1
                  ]
              | card <- cards
              ]
            <> [ Label
                   ("Continue having discarded " <> tshow n <> " cards")
                   [UseCardAbility iid source meta 1 NoPayment]
               ]
            )
    UseCardAbility iid source (Just (IntMetadata n)) 1 _
      | isSource attrs source -> do
        locationId <- getId @LocationId iid
        enemyIds <- getSetList @EnemyId locationId
        e <$ pushAll
          (replicate
            n
            (chooseOne iid
            $ [Label "Gain Resource" [TakeResources iid 1 False]]
            <> [ Label
                   "Spend Resource and Deal 1 Damage To Enemy At Your Location"
                   [ SpendResources iid 1
                   , chooseOne
                     iid
                     [ EnemyDamage enemyId iid source 1
                     | enemyId <- enemyIds
                     ]
                   ]
               | not (null enemyIds)
               ]
            )
          )
    _ -> BloodRite <$> runMessage msg attrs

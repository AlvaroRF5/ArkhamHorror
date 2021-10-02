module Arkham.Types.Event.Cards.Taunt2
  ( taunt2
  , Taunt2(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Target

newtype Taunt2 = Taunt2 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

taunt2 :: EventCard Taunt2
taunt2 = event Taunt2 Cards.taunt2

instance EventRunner env => RunMessage env Taunt2 where
  runMessage msg e@(Taunt2 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == eventId -> do
      lid <- getId @LocationId iid
      enemyIds <- getSetList lid
      e <$ push
        (chooseSome
          iid
          "Done engaging enemies"
          [ TargetLabel
              (EnemyTarget enemyId)
              [EngageEnemy iid enemyId False, DrawCards iid 1 False]
          | enemyId <- enemyIds
          ]
        )
    _ -> Taunt2 <$> runMessage msg attrs

module Arkham.Types.GameRunner where

import Arkham.Types.Classes
import Arkham.Types.EnemyId
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Query

type GameRunner env
  = ( HasQueue env
    , HasId LocationId InvestigatorId env
    , HasSet ConnectedLocationId LocationId env
    , HasSet EnemyId LocationId env
    , HasSet InvestigatorId LocationId env
    , HasCount ClueCount LocationId env
    )

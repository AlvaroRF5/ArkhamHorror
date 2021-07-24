module Arkham.Types.Location.Cards.SecurityOffice_129
  ( securityOffice_129
  , SecurityOffice_129(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (securityOffice_129)
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.LocationMatcher
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Window

newtype SecurityOffice_129 = SecurityOffice_129 LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

securityOffice_129 :: LocationCard SecurityOffice_129
securityOffice_129 = location
  SecurityOffice_129
  Cards.securityOffice_129
  3
  (PerPlayer 2)
  Diamond
  [Square]

instance HasModifiersFor env SecurityOffice_129

ability :: LocationAttrs -> Ability
ability attrs =
  (mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 2))
    { abilityLimit = PlayerLimit PerTurn 1
    }

instance ActionRunner env => HasActions env SecurityOffice_129 where
  getActions iid NonFast (SecurityOffice_129 attrs) =
    withBaseActions iid NonFast attrs
      $ pure [locationAbility iid (ability attrs)]
  getActions iid window (SecurityOffice_129 attrs) =
    getActions iid window attrs

instance LocationRunner env => RunMessage env SecurityOffice_129 where
  runMessage msg l@(SecurityOffice_129 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      unrevealedExhibitHalls <- map unUnrevealedLocationId
        <$> getSetList (LocationWithTitle "ExhibitHall")
      l <$ push
        (chooseOne
          iid
          (TargetLabel
              ScenarioDeckTarget
              [LookAtTopOfDeck iid ScenarioDeckTarget 1]
          : [ LookAtRevealed (toSource attrs) (LocationTarget exhibitHall)
            | exhibitHall <- unrevealedExhibitHalls
            ]
          )
        )
    _ -> SecurityOffice_129 <$> runMessage msg attrs

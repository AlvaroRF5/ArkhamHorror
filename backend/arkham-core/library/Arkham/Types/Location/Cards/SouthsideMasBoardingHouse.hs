module Arkham.Types.Location.Cards.SouthsideMasBoardingHouse
  ( SouthsideMasBoardingHouse(..)
  , southsideMasBoardingHouse
  )
where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype SouthsideMasBoardingHouse = SouthsideMasBoardingHouse Attrs
  deriving newtype (Show, ToJSON, FromJSON)

southsideMasBoardingHouse :: SouthsideMasBoardingHouse
southsideMasBoardingHouse = SouthsideMasBoardingHouse $ baseAttrs
  "01127"
  (Name "Southside" $ Just "Ma's Boarding House")
  EncounterSet.TheMidnightMasks
  2
  (PerPlayer 1)
  Square
  [Diamond, Plus, Circle]
  [Arkham]

instance HasModifiersFor env SouthsideMasBoardingHouse where
  getModifiersFor = noModifiersFor

ability :: Attrs -> Ability
ability attrs =
  (mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 1))
    { abilityLimit = PlayerLimit PerGame 1
    }

instance ActionRunner env => HasActions env SouthsideMasBoardingHouse where
  getActions iid NonFast (SouthsideMasBoardingHouse attrs@Attrs {..})
    | locationRevealed = withBaseActions iid NonFast attrs $ pure
      [ ActivateCardAbilityAction iid (ability attrs)
      | iid `member` locationInvestigators
      ]
  getActions iid window (SouthsideMasBoardingHouse attrs) =
    getActions iid window attrs

instance (LocationRunner env) => RunMessage env SouthsideMasBoardingHouse where
  runMessage msg l@(SouthsideMasBoardingHouse attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ unshiftMessage
        (SearchDeckForTraits iid (InvestigatorTarget iid) [Ally])
    _ -> SouthsideMasBoardingHouse <$> runMessage msg attrs

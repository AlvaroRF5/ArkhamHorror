module Arkham.Types.Location.Cards.DowntownFirstBankOfArkham
  ( DowntownFirstBankOfArkham(..)
  , downtownFirstBankOfArkham
  )
where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype DowntownFirstBankOfArkham = DowntownFirstBankOfArkham Attrs
  deriving newtype (Show, ToJSON, FromJSON)

downtownFirstBankOfArkham :: DowntownFirstBankOfArkham
downtownFirstBankOfArkham = DowntownFirstBankOfArkham $ baseAttrs
  "01130"
  (LocationName "Downtown" $ Just "First Bank of Arkham")
  EncounterSet.TheMidnightMasks
  3
  (PerPlayer 1)
  Triangle
  [Moon, T]
  [Arkham]

instance HasModifiersFor env DowntownFirstBankOfArkham where
  getModifiersFor = noModifiersFor

ability :: Attrs -> Ability
ability attrs =
  (mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 1))
    { abilityLimit = PlayerLimit PerGame 1
    }

instance ActionRunner env => HasActions env DowntownFirstBankOfArkham where
  getActions iid NonFast (DowntownFirstBankOfArkham attrs@Attrs {..})
    | locationRevealed = withBaseActions iid NonFast attrs $ do
      canGainResources <-
        notElem CannotGainResources
        . map modifierType
        <$> getInvestigatorModifiers iid (toSource attrs)
      pure
        [ ActivateCardAbilityAction iid (ability attrs)
        | canGainResources && iid `member` locationInvestigators
        ]
  getActions iid window (DowntownFirstBankOfArkham attrs) =
    getActions iid window attrs

instance (LocationRunner env) => RunMessage env DowntownFirstBankOfArkham where
  runMessage msg l@(DowntownFirstBankOfArkham attrs) = case msg of
    UseCardAbility iid source _ 1 | isSource attrs source ->
      l <$ unshiftMessage (TakeResources iid 3 False)
    _ -> DowntownFirstBankOfArkham <$> runMessage msg attrs

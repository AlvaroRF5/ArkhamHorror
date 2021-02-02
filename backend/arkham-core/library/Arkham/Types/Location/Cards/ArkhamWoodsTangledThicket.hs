module Arkham.Types.Location.Cards.ArkhamWoodsTangledThicket where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype ArkhamWoodsTangledThicket = ArkhamWoodsTangledThicket Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

arkhamWoodsTangledThicket :: ArkhamWoodsTangledThicket
arkhamWoodsTangledThicket = ArkhamWoodsTangledThicket $ base
  { locationRevealedConnectedSymbols = setFromList [Squiggle, T, Moon]
  , locationRevealedSymbol = Equals
  }
 where
  base = baseAttrs
    "01154"
    (Name "Arkham Woods" (Just "Tangled Thicket"))
    EncounterSet.TheDevourerBelow
    2
    (PerPlayer 1)
    Square
    [Squiggle]
    [Woods]

instance HasModifiersFor env ArkhamWoodsTangledThicket where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ArkhamWoodsTangledThicket where
  getActions i window (ArkhamWoodsTangledThicket attrs) =
    getActions i window attrs

instance (LocationRunner env) => RunMessage env ArkhamWoodsTangledThicket where
  runMessage msg (ArkhamWoodsTangledThicket attrs@Attrs {..}) = case msg of
    Investigate iid lid s _ False | lid == locationId -> do
      let investigate = Investigate iid lid s SkillCombat False
      ArkhamWoodsTangledThicket <$> runMessage investigate attrs
    _ -> ArkhamWoodsTangledThicket <$> runMessage msg attrs

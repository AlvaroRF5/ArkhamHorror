module Arkham.Types.Location.Cards.ArkhamWoodsTwistingPaths where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype ArkhamWoodsTwistingPaths = ArkhamWoodsTwistingPaths Attrs
  deriving newtype (Show, ToJSON, FromJSON)

arkhamWoodsTwistingPaths :: ArkhamWoodsTwistingPaths
arkhamWoodsTwistingPaths = ArkhamWoodsTwistingPaths $ base
  { locationRevealedConnectedSymbols = setFromList [Squiggle, Diamond, Equals]
  , locationRevealedSymbol = T
  }
 where
  base = baseAttrs
    "01151"
    (LocationName "Arkham Woods" (Just "Twisting Paths"))
    EncounterSet.TheDevourerBelow
    3
    (PerPlayer 1)
    Square
    [Squiggle]
    [Woods]

instance HasModifiersFor env ArkhamWoodsTwistingPaths where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ArkhamWoodsTwistingPaths where
  getActions i window (ArkhamWoodsTwistingPaths attrs) =
    getActions i window attrs

instance (LocationRunner env) => RunMessage env ArkhamWoodsTwistingPaths where
  runMessage msg l@(ArkhamWoodsTwistingPaths attrs@Attrs {..}) = case msg of
    Will (MoveTo iid lid)
      | iid `elem` locationInvestigators && lid /= locationId -> do
        moveFrom <- popMessage -- MoveFrom
        moveTo <- popMessage -- MoveTo
        l <$ unshiftMessages
          [ CreateEffect
            "01151"
            (Just $ EffectMessages (catMaybes [moveFrom, moveTo]))
            (toSource attrs)
            (InvestigatorTarget iid)
          , BeginSkillTest
            iid
            (LocationSource "01151")
            (InvestigatorTarget iid)
            Nothing
            SkillIntellect
            3
          ]
    _ -> ArkhamWoodsTwistingPaths <$> runMessage msg attrs

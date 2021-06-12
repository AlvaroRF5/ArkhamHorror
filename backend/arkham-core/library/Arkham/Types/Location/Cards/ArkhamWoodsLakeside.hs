module Arkham.Types.Location.Cards.ArkhamWoodsLakeside where

import Arkham.Prelude

import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Game.Helpers
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Name
import Arkham.Types.Source
import Arkham.Types.Trait

newtype ArkhamWoodsLakeside = ArkhamWoodsLakeside LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arkhamWoodsLakeside :: LocationId -> ArkhamWoodsLakeside
arkhamWoodsLakeside =
  ArkhamWoodsLakeside
    . (revealedConnectedSymbolsL .~ setFromList [Squiggle, Heart])
    . (revealedSymbolL .~ Star)
    . baseAttrs
        "50034"
        ("Arkham Woods" `subtitled` "Lakeside")
        EncounterSet.ReturnToTheDevourerBelow
        4
        (PerPlayer 1)
        Square
        [Squiggle]
        [Woods]

instance HasModifiersFor env ArkhamWoodsLakeside where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ArkhamWoodsLakeside where
  getActions i window (ArkhamWoodsLakeside attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env ArkhamWoodsLakeside where
  runMessage msg l@(ArkhamWoodsLakeside attrs@LocationAttrs {..}) = case msg of
    RevealToken (SkillTestSource _ _ source _ (Just Action.Investigate)) iid _
      | isSource attrs source && iid `elem` locationInvestigators -> do
        let
          ability = (mkAbility (toSource attrs) 0 ForcedAbility)
            { abilityLimit = PlayerLimit PerRound 1
            }
        unused <- getGroupIsUnused ability
        l <$ when
          unused
          (unshiftMessages [UseLimitedAbility iid ability, DrawAnotherToken iid]
          )
    _ -> ArkhamWoodsLakeside <$> runMessage msg attrs

module Arkham.Asset.Cards.ArchaicGlyphsGuidingStones3 (
  archaicGlyphsGuidingStones3,
  ArchaicGlyphsGuidingStones3 (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Investigator.Types (Field (..))
import Arkham.Location.Types (Field (..))
import Arkham.Matcher
import Arkham.Projection

newtype ArchaicGlyphsGuidingStones3 = ArchaicGlyphsGuidingStones3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

instance HasAbilities ArchaicGlyphsGuidingStones3 where
  getAbilities (ArchaicGlyphsGuidingStones3 a) =
    [ restrictedAbility a 1 ControlsThis $
        ActionAbility (Just Action.Investigate) $
          Costs [ActionCost 1, UseCost (AssetWithId $ toId a) Charge 1]
    ]

archaicGlyphsGuidingStones3 :: AssetCard ArchaicGlyphsGuidingStones3
archaicGlyphsGuidingStones3 =
  asset ArchaicGlyphsGuidingStones3 Cards.archaicGlyphsGuidingStones3

instance RunMessage ArchaicGlyphsGuidingStones3 where
  runMessage msg a@(ArchaicGlyphsGuidingStones3 attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      mlid <- field InvestigatorLocation iid
      case mlid of
        Nothing -> push $ Discard (toSource attrs) (toTarget attrs)
        Just lid -> do
          skillType <- field LocationInvestigateSkill lid
          pushAll
            [ Investigate
                iid
                lid
                (toSource attrs)
                (Just $ toTarget attrs)
                skillType
                False
            , Discard (toSource attrs) (toTarget attrs)
            ]
      pure a
    Successful (Action.Investigate, LocationTarget lid) iid _ target n
      | isTarget attrs target -> do
          clueCount <- field LocationClues lid
          let
            additional = n `div` 2
            amount = min clueCount (1 + additional)
          push $ InvestigatorDiscoverClues iid lid (toAbilitySource attrs 1) amount $ Just Action.Investigate
          pure a
    _ -> ArchaicGlyphsGuidingStones3 <$> runMessage msg attrs

module Arkham.Asset.Cards.DrElliHorowitz
  ( drElliHorowitz
  , DrElliHorowitz(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Card
import Arkham.ChaosBag.Base
import Arkham.Cost
import Arkham.Criteria
import Arkham.Keyword qualified as Keyword
import Arkham.Matcher
import Arkham.Placement
import Arkham.Projection
import Arkham.Scenario.Attrs ( Field (..) )
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Trait

newtype DrElliHorowitz = DrElliHorowitz AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drElliHorowitz :: AssetCard DrElliHorowitz
drElliHorowitz = ally DrElliHorowitz Cards.drElliHorowitz (1, 2)

instance HasModifiersFor DrElliHorowitz where
  getModifiersFor _ (AssetTarget aid) (DrElliHorowitz a) | aid /= toId a = do
    controller <- field AssetController (toId a)
    case controller of
      Nothing -> pure []
      Just iid -> do
        placement <- field AssetPlacement aid
        if placement == AttachedToAsset (toId a)
           then pure $ toModifiers a [AsIfUnderControlOf iid]
           else pure []
  getModifiersFor _ _ _ = pure []

instance HasAbilities DrElliHorowitz where
  getAbilities (DrElliHorowitz a) =
    [ restrictedAbility a 1 (ControlsThis <> CanManipulateDeck)
        $ ReactionAbility
            (AssetEntersPlay Timing.When $ AssetWithId $ toId a)
            Free
    ]

instance RunMessage DrElliHorowitz where
  runMessage msg a@(DrElliHorowitz attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ Search
        iid
        source
        (InvestigatorTarget iid)
        [fromTopOfDeck 9]
        AnyCard -- no filter because we need to handle game logic
        (DeferSearchedToTarget $ toTarget attrs)
      pure a
    SearchFound iid (isTarget attrs -> True) _ cards -> do
      validCards <- pure $ filter
        (`cardMatch` (CardWithType AssetType <> CardWithTrait Relic))
        cards
      tokens <- scenarioFieldMap ScenarioChaosBag chaosBagTokens
      let
        validAfterSeal c = do
          let
            sealTokenMatchers =
              flip mapMaybe (setToList $ cdKeywords $ toCardDef c) $ \case
                Keyword.Seal matcher -> Just $ matcher
                _ -> Nothing
          allM (\matcher -> anyM (\t -> matchToken iid t matcher) tokens) sealTokenMatchers
      validCardsAfterSeal <- filterM validAfterSeal validCards
      pushAll
        [ chooseOne
            iid
            [ TargetLabel
                (CardIdTarget $ toCardId c)
                [CreateAssetAt c $ AttachedToAsset $ toId attrs]
            | c <- validCardsAfterSeal
            ]
        ]
      pure a
    SearchNoneFound _ target | isTarget attrs target -> do
      push $ Label "No Cards Found" []
      pure a
    _ -> DrElliHorowitz <$> runMessage msg attrs

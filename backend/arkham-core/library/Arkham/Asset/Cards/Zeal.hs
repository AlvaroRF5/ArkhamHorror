module Arkham.Asset.Cards.Zeal (
  zeal,
  Zeal (..),
)
where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Card
import Arkham.Deck qualified as Deck
import Arkham.Investigator.Types (Field (..))
import Arkham.Matcher hiding (AssetCard)
import Arkham.Projection

newtype Zeal = Zeal AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

zeal :: AssetCard Zeal
zeal = asset Zeal Cards.zeal

instance HasAbilities Zeal where
  getAbilities (Zeal a) =
    [ controlledAbility a 1 (exists $ oneOf [assetIs Cards.hope, assetIs Cards.augur])
        $ ForcedAbility
        $ AssetEntersPlay #when
        $ AssetWithId (toId a)
    , controlledAbility a 2 (exists $ AssetWithId (toId a) <> AssetReady)
        $ fightAction
        $ OrCost [exhaust a, discardCost a]
    ]

instance RunMessage Zeal where
  runMessage msg a@(Zeal attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      otherCats <- select $ oneOf [assetIs Cards.hope, assetIs Cards.augur]
      for_ otherCats $ push . toDiscardBy iid (toAbilitySource attrs 1)
      pure a
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      let source = toAbilitySource attrs 2
      discarded <- selectNone $ AssetWithId (toId attrs)
      catsInDiscard <-
        fieldMap
          InvestigatorDiscard
          (filter (`cardMatch` oneOf [cardIs Cards.hope, cardIs Cards.augur]))
          iid
      player <- getPlayer iid
      zealCard <- field AssetCard (toId attrs)
      pushAll
        $ [skillTestModifier source iid (BaseSkillOf #combat 5)]
        <> [skillTestModifier source iid SkillTestAutomaticallySucceeds | discarded]
        <> [chooseFightEnemy iid source #combat]
        <> [ questionLabel "Put into play from discard" player
            $ ChooseOne
            $ [ CardLabel
                (toCardCode card)
                [ ShuffleCardsIntoDeck (Deck.InvestigatorDeck iid) [zealCard]
                , PutCardIntoPlay iid (toCard card) Nothing []
                ]
              | card <- catsInDiscard
              ]
            <> [Label "Skip" []]
           | notNull catsInDiscard
           ]
      pure a
    _ -> Zeal <$> runMessage msg attrs

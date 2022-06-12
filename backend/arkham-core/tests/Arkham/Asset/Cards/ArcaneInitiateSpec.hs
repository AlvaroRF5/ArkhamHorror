module Arkham.Asset.Cards.ArcaneInitiateSpec
  ( spec
  ) where

import TestImport.Lifted

import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Attrs
import Arkham.Investigator.Attrs hiding (assetsL)
import Arkham.Projection

spec :: Spec
spec = describe "Arcane Initiate" $ do
  it "enters play with 1 doom" $ do
    arcaneInitiate <- buildAsset "01063"
    investigator <- testInvestigator id
    gameTest
        investigator
        [playAsset investigator arcaneInitiate]
        (entitiesL . assetsL %~ insertEntity arcaneInitiate)
      $ do
          runMessages
          chooseOnlyOption "trigger forced ability"
          assert $ fieldP AssetDoom (== 1) (toId arcaneInitiate)

  it "can be exhausted to search the top 3 cards of your deck for a Spell card"
    $ do
        arcaneInitiate <- buildAsset "01063"
        investigator <- testInvestigator id
        card <- genPlayerCard Cards.shrivelling
        otherCards <- testPlayerCards 2
        gameTest
            investigator
            [ loadDeck investigator (card : otherCards)
            , playAsset investigator arcaneInitiate
            ]
            (entitiesL . assetsL %~ insertEntity arcaneInitiate)
          $ do
              runMessages
              chooseOnlyOption "trigger forced ability"
              [_, ability] <- field AssetAbilities $ toId arcaneInitiate
              push $ UseAbility (toId investigator) ability []
              runMessages
              chooseOnlyOption "search top of deck"
              chooseOnlyOption "take spell card"
              assert $ fieldP InvestigatorHand (== [PlayerCard card]) (toId investigator)

  it "should continue if no Spell card is found" $ do
    arcaneInitiate <- buildAsset "01063"
    investigator <- testInvestigator id
    cards <- testPlayerCards 3
    gameTest
        investigator
        [loadDeck investigator cards, playAsset investigator arcaneInitiate]
        (entitiesL . assetsL %~ insertEntity arcaneInitiate)
      $ do
          runMessages
          chooseOnlyOption "trigger forced ability"
          [_, ability] <- field AssetAbilities $ toId arcaneInitiate
          push $ UseAbility (toId investigator) ability []
          runMessages
          chooseOnlyOption "search top of deck"
          chooseOptionMatching
            "no cards found"
            (\case
              Label{} -> True
              _ -> False
            )
          assert $ fieldP InvestigatorHand null (toId investigator)

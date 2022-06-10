{-# OPTIONS_GHC -Wno-orphans #-}
module Arkham.Campaign.Runner (module X) where

import Arkham.Prelude

import Arkham.Card.CardDef
import Arkham.Campaign.Attrs as X
import Arkham.Classes.HasQueue
import Arkham.Classes.RunMessage
import Arkham.Helpers
import Arkham.Helpers.Query
import Arkham.Id
import Arkham.Message
import Arkham.Projection
import Arkham.CampaignStep
import Arkham.CampaignLog
import Arkham.CampaignLogKey
import Arkham.Card.PlayerCard
import Arkham.Scenario.Attrs (Field(..))

instance RunMessage CampaignAttrs where
  runMessage msg a@CampaignAttrs {..} = case msg of
    StartCampaign -> a <$ push (CampaignStep campaignStep)
    CampaignStep Nothing -> a <$ push GameOver -- TODO: move to generic
    CampaignStep (Just (ScenarioStep sid)) -> do
      a <$ pushAll [ResetGame, StartScenario sid]
    CampaignStep (Just (UpgradeDeckStep _)) -> do
      investigatorIds <- getInvestigatorIds
      a <$ pushAll
        (ResetGame
        : map chooseUpgradeDeck investigatorIds
        <> [FinishedUpgradingDecks]
        )
    SetTokensForScenario -> a <$ push (SetTokens campaignChaosBag)
    AddCampaignCardToDeck iid cardDef -> do
      card <- lookupPlayerCard cardDef <$> getRandom
      pure $ a & storyCardsL %~ insertWith
        (<>)
        iid
        [card { pcBearer = Just iid }]
    RemoveCampaignCardFromDeck iid cardCode ->
      pure
        $ a
        & storyCardsL
        %~ adjustMap (filter ((/= cardCode) . cdCardCode . toCardDef)) iid
    AddToken token -> pure $ a & chaosBagL %~ (token :)
    RemoveAllTokens token -> pure $ a & chaosBagL %~ filter (/= token)
    InitDeck iid deck -> do
      (deck', randomWeaknesses) <- addRandomBasicWeaknessIfNeeded deck
      pushAll $ map (AddCampaignCardToDeck iid) randomWeaknesses
      pure $ a & decksL %~ insertMap iid deck'
    UpgradeDeck iid deck -> do
      -- We remove the random weakness if the upgrade deck still has it listed
      -- since this will have been added at the beginning of the campaign
      (deck', _) <- addRandomBasicWeaknessIfNeeded deck
      pure $ a & decksL %~ insertMap iid deck'
    FinishedUpgradingDecks -> case a ^. stepL of
      Just (UpgradeDeckStep nextStep) -> do
        push (CampaignStep $ Just nextStep)
        pure $ a & stepL ?~ nextStep
      _ -> error "invalid state"
    ResetGame -> do
      for_ (mapToList campaignDecks) $ \(iid, deck) -> do
        let investigatorStoryCards = findWithDefault [] iid campaignStoryCards
        push (LoadDeck iid . Deck $ unDeck deck <> investigatorStoryCards)
      pure a
    CrossOutRecord key -> do
      let
        crossedOutModifier =
          if key `member` view (logL . recorded) a then insertSet key else id

      pure
        $ a
        & (logL . recorded %~ deleteSet key)
        & (logL . crossedOut %~ crossedOutModifier)
        & (logL . recordedSets %~ deleteMap key)
        & (logL . recordedCounts %~ deleteMap key)
    Record key -> pure $ a & logL . recorded %~ insertSet key
    RecordSet key cardCodes ->
      pure $ a & logL . recordedSets %~ insertMap key (map Recorded cardCodes)
    RecordSetInsert key cardCodes ->
      pure $ case a ^. logL . recordedSets . at key of
        Nothing ->
          a & logL . recordedSets %~ insertMap key (map Recorded cardCodes)
        Just set ->
          let
            set' =
              filter ((`notElem` cardCodes) . unrecorded) set
                <> map Recorded cardCodes
          in a & logL . recordedSets %~ insertMap key set'
    CrossOutRecordSetEntries key cardCodes ->
      pure
        $ a
        & logL
        . recordedSets
        %~ adjustMap
             (map
               (\case
                 Recorded c | c `elem` cardCodes -> CrossedOut c
                 other -> other
               )
             )
             key
    RecordCount key int ->
      pure $ a & logL . recordedCounts %~ insertMap key int
    ScenarioResolution r -> case campaignStep of
      Just (ScenarioStep sid) -> pure $ a & resolutionsL %~ insertMap sid r
      _ -> error "must be called in a scenario"
    DrivenInsane iid -> pure $ a & logL . recordedSets %~ insertWith
      (<>)
      DrivenInsaneInvestigators
      (singleton $ Recorded $ unInvestigatorId iid)
    _ -> pure a


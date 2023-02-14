module Arkham.Scenario.Scenarios.CarnevaleOfHorrors
  ( CarnevaleOfHorrors(..)
  , carnevaleOfHorrors
  ) where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Asset.Cards qualified as Assets
import Arkham.Attack
import Arkham.CampaignLogKey
import Arkham.Card
import Arkham.Classes
import Arkham.Difficulty
import Arkham.Direction
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Investigator
import Arkham.Id
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher hiding ( RevealLocation )
import Arkham.Message
import Arkham.Placement
import Arkham.Resolution
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.Scenarios.CarnevaleOfHorrors.FlavorText qualified as Flavor
import Arkham.Scenarios.CarnevaleOfHorrors.Helpers
import Arkham.Source
import Arkham.Target
import Arkham.Token
import Arkham.Trait hiding ( Cultist )
import Data.List.NonEmpty qualified as NE

newtype CarnevaleOfHorrors = CarnevaleOfHorrors ScenarioAttrs
  deriving stock Generic
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

carnevaleOfHorrors :: Difficulty -> CarnevaleOfHorrors
carnevaleOfHorrors difficulty = scenario
  CarnevaleOfHorrors
  "82001"
  "Carnevale of Horrors"
  difficulty
  [ ".         .         .         location1  .         .         ."
  , ".         location8 location8 location1  location2 location2 ."
  , ".         location8 location8 .          location2 location2 ."
  , "location7 location7 .         cnidathqua gondola   location3 location3"
  , ".         location6 location6 .          location4 location4 ."
  , ".         location6 location6 location5  location4 location4 ."
  , ".         .         .         location5  .         .         ."
  ]

instance HasTokenValue CarnevaleOfHorrors where
  getTokenValue iid tokenFace (CarnevaleOfHorrors attrs) = case tokenFace of
    Skull -> do
      let
        countInnocentRevelers = count ((== Assets.innocentReveler) . toCardDef)
        innocentRevelerCount =
          countInnocentRevelers (scenarioCardsUnderAgendaDeck attrs)
            + (if isEasyStandard attrs
                then 0
                else countInnocentRevelers (scenarioCardsUnderActDeck attrs)
              )
      pure $ TokenValue Skull (NegativeModifier $ 2 + innocentRevelerCount)
    Cultist -> pure $ TokenValue Cultist NoModifier
    Tablet -> pure $ toTokenValue attrs Tablet 3 4
    ElderThing -> pure $ toTokenValue attrs ElderThing 4 6
    otherFace -> getTokenValue iid otherFace attrs

masks :: [CardDef]
masks =
  [Assets.pantalone, Assets.medicoDellaPeste, Assets.bauta, Assets.gildedVolto]

sacrificesMade :: [InvestigatorId] -> ScenarioAttrs -> [Message]
sacrificesMade investigatorIds s =
  story investigatorIds Flavor.sacrificesMade
    : [ SearchCollectionForRandom
          iid
          (toSource s)
          (CardWithType PlayerTreacheryType
          <> CardWithOneOf (map CardWithTrait [Madness, Injury, Monster])
          )
      | iid <- investigatorIds
      ]

abbessSatisfied :: InvestigatorId -> [InvestigatorId] -> [Message]
abbessSatisfied leadInvestigatorId investigatorIds =
  story investigatorIds Flavor.abbessSatisfied
    : [ addCampaignCardToDeckChoice
          leadInvestigatorId
          investigatorIds
          Assets.abbessAllegriaDiBiase
      ]

additionalRewards :: HasGame m => ScenarioAttrs -> m [Message]
additionalRewards s = do
  leadInvestigatorId <- getLeadInvestigatorId
  investigatorIds <- allInvestigatorIds
  let
    proceedToSacrificesMade =
      if null (scenarioCardsUnderActDeck s)
          && notNull (scenarioCardsUnderAgendaDeck s)
        then sacrificesMade investigatorIds s
        else []
    proceedToAbbessSatisfied =
      if null (scenarioCardsUnderAgendaDeck s)
          && length (scenarioCardsUnderAgendaDeck s)
          == 3
        then abbessSatisfied leadInvestigatorId investigatorIds
        else []
  pure
    $ [ChooseOneRewardByEachPlayer masks investigatorIds]
    <> proceedToSacrificesMade
    <> proceedToAbbessSatisfied

instance RunMessage CarnevaleOfHorrors where
  runMessage msg s@(CarnevaleOfHorrors attrs) = case msg of
    Setup -> do
      investigatorIds <- allInvestigatorIds

      -- Encounter Deck
      encounterDeck <- buildEncounterDeckExcluding
        [ Enemies.donLagorio
        , Enemies.elisabettaMagro
        , Enemies.salvatoreNeri
        , Enemies.savioCorvi
        , Enemies.cnidathqua
        ]
        [EncounterSet.CarnevaleOfHorrors]

      -- Locations
      let locationLabels = [ "location" <> tshow @Int n | n <- [1 .. 8] ]
      randomLocations <- traverse genCard . drop 1 =<< shuffleM
        [ Locations.streetsOfVenice
        , Locations.rialtoBridge
        , Locations.venetianGarden
        , Locations.bridgeOfSighs
        , Locations.floodedSquare
        , Locations.accademiaBridge
        , Locations.theGuardian
        ]
      canalSide <- genCard Locations.canalSide
      sanMarcoBasilica <- genCard Locations.sanMarcoBasilica

      let
        unshuffled = canalSide : randomLocations
        nonSanMarcoBasilicaLocationIds = map (LocationId . toCardId) unshuffled
        sanMarcoBasilicaId = LocationId $ toCardId sanMarcoBasilica

      locationIdsWithMaskedCarnevaleGoers <-
        zip nonSanMarcoBasilicaLocationIds
          <$> (shuffleM =<< traverse
                genCard
                [ Assets.maskedCarnevaleGoer_17
                , Assets.maskedCarnevaleGoer_18
                , Assets.maskedCarnevaleGoer_19
                , Assets.maskedCarnevaleGoer_20
                , Assets.maskedCarnevaleGoer_21
                , Assets.maskedCarnevaleGoer_21
                , Assets.maskedCarnevaleGoer_21
                ]
              )
      locations <- (sanMarcoBasilica :|) <$> shuffleM unshuffled

      -- Assets
      abbess <- genCard Assets.abbessAllegriaDiBiase

      pushAll
        $ [SetEncounterDeck encounterDeck, SetAgendaDeck, SetActDeck]
        <> [ PlaceLocation cardDef | cardDef <- toList locations ]
        <> [ SetLocationLabel (LocationId $ toCardId location) label
           | (label, location) <- zip locationLabels (toList locations)
           ]
        <> [ PlacedLocationDirection
               (LocationId $ toCardId l2)
               RightOf
               (LocationId $ toCardId l1)
           | (l1, l2) <- zip (toList locations) (drop 1 $ toList locations)
           ]
        <> [ PlacedLocationDirection
               (LocationId . toCardId $ NE.head locations)
               RightOf
               (LocationId . toCardId $ NE.last locations)
           ]
        <> [ CreateAssetAt asset (AtLocation locationId)
           | (locationId, asset) <- locationIdsWithMaskedCarnevaleGoers
           ]
        <> [ CreateAssetAt abbess (AtLocation sanMarcoBasilicaId)
           , RevealLocation Nothing sanMarcoBasilicaId
           , MoveAllTo (toSource attrs) sanMarcoBasilicaId
           , story investigatorIds Flavor.intro
           ]

      setAsideCards <- traverse
        genCard
        [ Enemies.cnidathqua
        , Assets.pantalone
        , Assets.medicoDellaPeste
        , Assets.bauta
        , Assets.gildedVolto
        ]

      CarnevaleOfHorrors <$> runMessage
        msg
        (attrs
        & (setAsideCardsL .~ setAsideCards)
        & (actStackL
          . at 1
          ?~ [Acts.theCarnevaleConspiracy, Acts.getToTheBoats, Acts.row]
          )
        & (agendaStackL
          . at 1
          ?~ [ Agendas.theFestivitiesBegin
             , Agendas.theShadowOfTheEclipse
             , Agendas.chaosAtTheCarnevale
             ]
          )
        )
    SetTokensForScenario -> do
      let
        tokens = if isEasyStandard attrs
          then
            [ PlusOne
            , Zero
            , Zero
            , Zero
            , MinusOne
            , MinusOne
            , MinusOne
            , MinusTwo
            , MinusThree
            , MinusFour
            , MinusSix
            , Skull
            , Skull
            , Skull
            , Cultist
            , Tablet
            , ElderThing
            , AutoFail
            , ElderSign
            ]
          else
            [ PlusOne
            , Zero
            , Zero
            , Zero
            , MinusOne
            , MinusOne
            , MinusThree
            , MinusFour
            , MinusFive
            , MinusSix
            , MinusSeven
            , Skull
            , Skull
            , Skull
            , Cultist
            , Tablet
            , ElderThing
            , AutoFail
            , ElderSign
            ]
      s <$ push (SetTokens tokens)
    ResolveToken _ Cultist iid -> s <$ push (DrawAnotherToken iid)
    ResolveToken token Tablet iid | isHardExpert attrs -> do
      lid <- getJustLocation iid
      closestInnocentRevelers <- selectList $ ClosestAsset lid $ assetIs
        Assets.innocentReveler
      case closestInnocentRevelers of
        [] -> pure ()
        [x] -> push
          (chooseOne
            iid
            [ ComponentLabel
              (AssetComponent x DamageToken)
              [AssetDamage x (TokenSource token) 1 0]
            , ComponentLabel
              (AssetComponent x HorrorToken)
              [AssetDamage x (TokenSource token) 0 1]
            ]
          )
        xs -> push
          (chooseOne
            iid
            [ TargetLabel
                (AssetTarget x)
                [ chooseOne
                    iid
                    [ ComponentLabel
                      (AssetComponent x DamageToken)
                      [AssetDamage x (TokenSource token) 1 0]
                    , ComponentLabel
                      (AssetComponent x HorrorToken)
                      [AssetDamage x (TokenSource token) 0 1]
                    ]
                ]
            | x <- xs
            ]
          )
      pure s
    FailedSkillTest iid _ _ (TokenTarget token) _ _ -> do
      case tokenFace token of
        Cultist -> push $ InvestigatorDrawEncounterCard iid
        Tablet -> do
          lid <- getJustLocation iid
          closestInnocentRevelers <- selectList $ ClosestAsset lid $ assetIs
            Assets.innocentReveler
          case closestInnocentRevelers of
            [] -> pure ()
            [x] -> push $ chooseOne
              iid
              [ ComponentLabel
                (AssetComponent x DamageToken)
                [AssetDamage x (TokenSource token) 1 0]
              , ComponentLabel
                (AssetComponent x HorrorToken)
                [AssetDamage x (TokenSource token) 0 1]
              ]
            xs -> push $ chooseOne
              iid
              [ targetLabel
                  x
                  [ chooseOne
                      iid
                      [ ComponentLabel
                        (AssetComponent x DamageToken)
                        [AssetDamage x (TokenSource token) 1 0]
                      , ComponentLabel
                        (AssetComponent x HorrorToken)
                        [AssetDamage x (TokenSource token) 0 1]
                      ]
                  ]
              | x <- xs
              ]
        ElderThing -> do
          mCnidathquaId <- getCnidathqua
          case mCnidathquaId of
            Just cnidathquaId -> push $ EnemyAttack
              iid
              cnidathquaId
              (DamageFirst Assets.innocentReveler)
              RegularAttack
            Nothing -> pure ()
        _ -> pure ()
      pure s
    ScenarioResolution NoResolution -> do
      iids <- allInvestigatorIds
      xp <- getXp
      additionalRewardsMsg <- additionalRewards
        (attrs
        & (cardsUnderActDeckL %~ drop 1)
        & (cardsUnderAgendaDeckL <>~ take 1 (scenarioCardsUnderActDeck attrs))
        )
      pushAll
        $ [ story iids Flavor.noResolution
          , Record ManyWereSacrificedToCnidathquaDuringTheCarnivale
          ]
        <> additionalRewardsMsg
        <> [ GainXP iid n | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    ScenarioResolution (Resolution 1) -> do
      iids <- allInvestigatorIds
      xp <- getXp
      additionalRewardsMsg <- additionalRewards attrs
      pushAll
        $ [ story iids Flavor.resolution1
          , Record TheSunBanishedCnidathquaIntoTheDepths
          ]
        <> additionalRewardsMsg
        <> [ GainXP iid n | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    ScenarioResolution (Resolution 2) -> do
      iids <- allInvestigatorIds
      xp <- getXp
      additionalRewardsMsg <- additionalRewards attrs
      pushAll
        $ [ story iids Flavor.resolution2
          , Record CnidathquaRetreatedToNurseItsWounds
          ]
        <> additionalRewardsMsg
        <> [ GainXP iid n | (iid, n) <- xp ]
        <> [EndOfGame Nothing]
      pure s
    ChooseOneRewardByEachPlayer rewards@(_ : _) (currentInvestigatorId : rest)
      -> do
        push
          $ chooseOne currentInvestigatorId
          $ Label "Do not add a mask" [ChooseOneRewardByEachPlayer rewards rest]
          : [ CardLabel
                (toCardCode reward)
                [ AddCampaignCardToDeck currentInvestigatorId reward
                , ChooseOneRewardByEachPlayer (delete reward rewards) rest
                ]
            | reward <- rewards
            ]
        pure s
    RequestedPlayerCard iid source mcard | isSource attrs source -> do
      for_ mcard $ push . AddCardToDeckForCampaign iid
      pure s
    _ -> CarnevaleOfHorrors <$> runMessage msg attrs

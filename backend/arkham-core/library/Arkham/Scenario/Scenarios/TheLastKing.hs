module Arkham.Scenario.Scenarios.TheLastKing
  ( TheLastKing(..)
  , theLastKing
  ) where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Act.Types ( Field (..) )
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Asset.Cards qualified as Assets
import Arkham.Asset.Types ( Field (..) )
import Arkham.CampaignLogKey
import Arkham.CampaignStep
import Arkham.Card
import Arkham.Classes
import Arkham.Difficulty
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Helpers.Enemy
import Arkham.Helpers.Investigator
import Arkham.Investigator.Types ( Field (..) )
import Arkham.Location.Cards qualified as Locations
import Arkham.Location.Types ( Field (..) )
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Name
import Arkham.Placement
import Arkham.Projection
import Arkham.Resolution
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.ScenarioLogKey
import Arkham.Scenarios.TheLastKing.Story
import Arkham.Source
import Arkham.Story.Cards qualified as Story
import Arkham.Target
import Arkham.Token
import Arkham.Trait qualified as Trait

newtype TheLastKing = TheLastKing ScenarioAttrs
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theLastKing :: Difficulty -> TheLastKing
theLastKing difficulty = scenario
  TheLastKing
  "03061"
  "The Last King"
  difficulty
  [ "diningRoom .         gallery"
  , "ballroom   courtyard livingRoom"
  , ".          foyer     ."
  ]

instance HasTokenValue TheLastKing where
  getTokenValue iid tokenFace (TheLastKing attrs) = case tokenFace of
    Skull -> pure $ TokenValue Skull NoModifier
    Cultist -> pure $ toTokenValue attrs Cultist 2 3
    Tablet -> pure $ TokenValue Tablet (NegativeModifier 4)
    ElderThing -> do
      lid <- getJustLocation iid
      shroud <- field LocationShroud lid
      pure $ TokenValue ElderThing (NegativeModifier shroud)
    otherFace -> getTokenValue iid otherFace attrs

standaloneTokens :: [TokenFace]
standaloneTokens =
  [ PlusOne
  , Zero
  , Zero
  , MinusOne
  , MinusOne
  , MinusOne
  , MinusTwo
  , MinusTwo
  , MinusThree
  , MinusFour
  , Skull
  , Skull
  , Skull
  , AutoFail
  , ElderSign
  ]

interviewedToCardCode :: ScenarioLogKey -> Maybe CardCode
interviewedToCardCode = \case
  InterviewedConstance -> Just $ toCardCode Assets.constanceDumaine
  InterviewedJordan -> Just $ toCardCode Assets.jordanPerry
  InterviewedHaruko -> Just $ toCardCode Assets.ishimaruHaruko
  InterviewedSebastien -> Just $ toCardCode Assets.sebastienMoreau
  InterviewedAshleigh -> Just $ toCardCode Assets.ashleighClarke
  _ -> Nothing

instance RunMessage TheLastKing where
  runMessage msg s@(TheLastKing attrs) = case msg of
    SetTokensForScenario -> do
      randomToken <- sample (Cultist :| [Tablet, ElderThing])
      whenStandalone
        $ push (SetTokens $ standaloneTokens <> [randomToken, randomToken])
      pure s
    StandaloneSetup -> do
      lead <- getLead
      push $ AddCampaignCardToDeck lead Enemies.theManInThePallidMask
      pure s
    Setup -> do
      encounterDeck <- buildEncounterDeckExcluding
        [Enemies.dianneDevine]
        [ EncounterSet.TheLastKing
        , EncounterSet.HastursGift
        , EncounterSet.DecayAndFilth
        , EncounterSet.TheStranger
        , EncounterSet.AncientEvils
        ]

      (foyerId, placeFoyer) <- placeLocationCard Locations.foyer
      otherPlacements <- traverse
        placeLocationCard
        [ Locations.courtyard
        , Locations.livingRoom
        , Locations.ballroom
        , Locations.diningRoom
        , Locations.gallery
        ]

      totalClues <- getPlayerCountValue (StaticWithPerPlayer 1 1)

      bystanders <-
        traverse (\c -> (c, ) <$> getRandom) =<< shuffleM =<< genCards
          [ Assets.constanceDumaine
          , Assets.jordanPerry
          , Assets.ishimaruHaruko
          , Assets.sebastienMoreau
          , Assets.ashleighClarke
          ]

      destinations <- shuffleM $ map fst otherPlacements
      investigatorIds <- allInvestigatorIds

      pushAll
        $ [ story investigatorIds intro
          , SetEncounterDeck encounterDeck
          , SetAgendaDeck
          , SetActDeck
          , placeFoyer
          ]
        <> map snd otherPlacements
        <> [MoveAllTo (toSource attrs) foyerId]
        <> zipWith
             (\(bystander, assetId) placement ->
               CreateAssetAt assetId bystander placement
             )
             bystanders
             (map AtLocation destinations)
        <> [ PlaceClues (toTarget assetId) totalClues
           | (_, assetId) <- bystanders
           ]

      setAsideEncounterCards <- genCards [Enemies.dianneDevine]

      storyCards <- genCards
        [ Story.sickeningReality_65
        , Story.sickeningReality_66
        , Story.sickeningReality_67
        , Story.sickeningReality_68
        , Story.sickeningReality_69
        ]
      agendas <- genCards [Agendas.fashionablyLate, Agendas.theTerrifyingTruth]
      acts <- genCards [Acts.discoveringTheTruth]

      TheLastKing <$> runMessage
        msg
        (attrs
        & (setAsideCardsL .~ setAsideEncounterCards)
        & (cardsUnderScenarioReferenceL .~ storyCards)
        & (actStackL . at 1 ?~ acts)
        & (agendaStackL . at 1 ?~ agendas)
        )
    ResolveToken _ token iid | token `elem` [Skull, Cultist, Tablet] ->
      s <$ case token of
        Skull -> push (DrawAnotherToken iid)
        Cultist | isHardExpert attrs -> do
          clueCount <- field InvestigatorClues iid
          when (clueCount > 0) (push $ InvestigatorPlaceCluesOnLocation iid 1)

        Tablet | isHardExpert attrs -> push $ InvestigatorAssignDamage
          iid
          (TokenEffectSource token)
          DamageAny
          0
          1
        _ -> pure ()
    FailedSkillTest iid _ _ (TokenTarget token) _ _ ->
      s <$ case tokenFace token of
        Skull -> do
          targets <- selectListMap EnemyTarget $ if isEasyStandard attrs
            then EnemyWithTrait Trait.Lunatic
            else EnemyWithMostRemainingHealth $ EnemyWithTrait Trait.Lunatic
          when
            (notNull targets)
            (push $ chooseOrRunOne
              iid
              [ TargetLabel target [PlaceDoom target 1] | target <- targets ]
            )
        Cultist | isEasyStandard attrs -> do
          clueCount <- field InvestigatorClues iid
          when (clueCount > 0) (push $ InvestigatorPlaceCluesOnLocation iid 1)
        Tablet | isEasyStandard attrs -> push
          (InvestigatorAssignDamage iid (TokenSource token) DamageAny 0 1)
        ElderThing | isHardExpert attrs ->
          push (InvestigatorAssignDamage iid (TokenSource token) DamageAny 1 0)
        _ -> pure ()
    ResolveStory _ story' | cdName story' == "Sickening Reality" -> do
      let
        findPair
          | story' == Story.sickeningReality_65
          = (Assets.constanceDumaine, Enemies.constanceDumaine)
          | story' == Story.sickeningReality_66
          = (Assets.jordanPerry, Enemies.jordanPerry)
          | story' == Story.sickeningReality_67
          = (Assets.ishimaruHaruko, Enemies.ishimaruHaruko)
          | story' == Story.sickeningReality_68
          = (Assets.sebastienMoreau, Enemies.sebastienMoreau)
          | story' == Story.sickeningReality_69
          = (Assets.ashleighClarke, Enemies.ashleighClarke)
          | otherwise
          = error "Invalid story"
        (asset, enemy) = findPair

      assetId <- fromJustNote "missing" <$> selectOne (assetIs asset)
      enemyCard <- genCard enemy
      lid <- fieldMap
        AssetLocation
        (fromJustNote "must be at a location")
        assetId
      iids <- selectList $ InvestigatorAt $ LocationWithId lid
      clues <- field AssetClues assetId
      enemyCreation <- createEnemy enemyCard lid
      pushAll
        $ [ InvestigatorAssignDamage
              iid
              (StorySource $ cdCardCode story')
              DamageAny
              0
              1
          | iid <- iids
          ]
        <> [ RemoveClues (AssetTarget assetId) clues
           , PlaceClues (LocationTarget lid) clues
           , RemoveFromGame (AssetTarget assetId)
           , enemyCreation
           ]
      pure s
    ResolveStory _ story' -> do
      let
        remember
          | story' == Story.engramsOath = InterviewedConstance
          | story' == Story.langneauPerdu = InterviewedJordan
          | story' == Story.thePattern = InterviewedHaruko
          | story' == Story.theFirstShow = InterviewedSebastien
          | story' == Story.aboveAndBelow = InterviewedAshleigh
          | otherwise = error "invalid story"
      s <$ push (Remember remember)
    ScenarioResolution NoResolution -> do
      anyResigned <- notNull <$> select ResignedInvestigator
      s <$ push (ScenarioResolution $ Resolution $ if anyResigned then 1 else 2)
    ScenarioResolution (Resolution n) -> do
      -- Resolution handles XP in a special way, we must divvy up between investigators
      -- evenly and apply, this will have a weird interaction with Hospital Debts so we
      -- want to handle `getXp` in two phases. The first phase will essentially evenly
      -- add XP modifiers to the players in order to have `getXp` resolve "normally"
      investigatorIds <- allInvestigatorIds
      investigatorIdsWithNames <- forToSnd
        investigatorIds
        (field InvestigatorName)
      lead <- getLead
      clueCounts <- traverse (field ActClues) =<< selectList AnyAct
      vipsSlain <-
        selectListMap toCardCode $ VictoryDisplayCardMatch $ CardWithTrait
          Trait.Lunatic
      let
        interviewed =
          mapMaybe interviewedToCardCode (setToList $ scenarioLog attrs)
        extraXp = ceiling @Double (fromIntegral (sum clueCounts) / 2)
        (assignedXp, remainingXp) = quotRem extraXp (length investigatorIds)
        assignXp amount iid = CreateWindowModifierEffect
          EffectGameWindow
          (EffectModifiers $ toModifiers (toSource attrs) [XPModifier amount])
          (toSource attrs)
          (InvestigatorTarget iid)
      s <$ pushAll
        ([ assignXp assignedXp iid | iid <- investigatorIds ]
        <> [ chooseN
               lead
               remainingXp
               [ Label
                   ("Choose " <> display name <> " to gain 1 additional XP")
                   [assignXp 1 iid]
               | (iid, name) <- investigatorIdsWithNames
               ]
           ]
        <> [ recordSetInsert VIPsInterviewed interviewed | notNull interviewed ]
        <> [ recordSetInsert VIPsSlain vipsSlain | notNull vipsSlain ]
        <> if n == 2 || n == 3
             then
               [ RemoveAllTokens Cultist
               , RemoveAllTokens Tablet
               , RemoveAllTokens ElderThing
               , AddToken Cultist
               , AddToken Tablet
               , AddToken ElderThing
               ]
             else
               []
               <> [ crossOutRecordSetEntries VIPsInterviewed interviewed
                  | n == 3
                  ]
               <> [ScenarioResolutionStep 1 (Resolution n)]
        )
    ScenarioResolutionStep 1 (Resolution n) -> do
      investigatorIds <- allInvestigatorIds
      gainXp <- toGainXp getXp
      s <$ case n of
        1 ->
          pushAll
            $ [story investigatorIds resolution1]
            <> gainXp
            <> [EndOfGame (Just $ InterludeStep 1 Nothing)]
        2 ->
          pushAll
            $ [story investigatorIds resolution2]
            <> gainXp
            <> [EndOfGame Nothing]
        3 ->
          pushAll
            $ [story investigatorIds resolution3]
            <> gainXp
            <> [EndOfGame Nothing]
        _ -> error "Invalid resolution"
    _ -> TheLastKing <$> runMessage msg attrs

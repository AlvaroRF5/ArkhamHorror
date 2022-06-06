module Arkham.Scenario.Scenarios.TheUnspeakableOath
  ( TheUnspeakableOath(..)
  , theUnspeakableOath
  ) where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Asset.Cards qualified as Assets
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Location.Cards qualified as Locations
import Arkham.Scenarios.TheUnspeakableOath.Story
import Arkham.CampaignLogKey
import Arkham.CampaignStep
import Arkham.Card
import Arkham.Card.PlayerCard
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Helpers
import Arkham.Id
import Arkham.Matcher hiding (PlaceUnderneath)
import Arkham.Message
import Arkham.Query
import Arkham.Resolution
import Arkham.Scenario.Attrs
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.Source
import Arkham.Target
import Arkham.Token
import Arkham.Trait hiding (Cultist, Expert)

newtype TheUnspeakableOath = TheUnspeakableOath ScenarioAttrs
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theUnspeakableOath :: Difficulty -> TheUnspeakableOath
theUnspeakableOath difficulty =
  TheUnspeakableOath
    $ baseAttrs "03159" "The Unspeakable Oath" difficulty
    & locationLayoutL
    ?~ [ ".       .       .        .        garden                        garden                        .                             .                             .                   ."
       , ".       .       .        .        yard                          yard                          .                             .                             .                   ."
       , "kitchen kitchen messHall messHall asylumHallsWesternPatientWing asylumHallsWesternPatientWing asylumHallsEasternPatientWing asylumHallsEasternPatientWing infirmary           infirmary"
       , ".       .       .        .        patientConfinement1           patientConfinement1           basementHall                  basementHall                  patientConfinement2 patientConfinement2"
       , ".       .       .        .        .                             patientConfinement3           patientConfinement3           patientConfinement4           patientConfinement4 ."
       ]
    & decksL
    .~ mapFromList [(LunaticsDeck, []), (MonstersDeck, [])]

instance HasRecord env TheUnspeakableOath where
  hasRecord _ _ = pure False
  hasRecordSet _ _ = pure []
  hasRecordCount _ _ = pure 0

instance
  ( HasTokenValue env InvestigatorId
  , HasCount Shroud env LocationId
  , HasCount HorrorCount env InvestigatorId
  , HasId LocationId env InvestigatorId
  )
  => HasTokenValue env TheUnspeakableOath where
  getTokenValue iid tokenFace (TheUnspeakableOath attrs) = case tokenFace of
    Skull -> pure $ if isEasyStandard attrs
      then TokenValue Skull (NegativeModifier 1)
      else TokenValue Skull NoModifier
    Cultist -> do
      horror <- unHorrorCount <$> getCount iid
      pure $ TokenValue Cultist (NegativeModifier horror)
    Tablet -> do
      lid <- getId @LocationId iid
      shroud <- unShroud <$> getCount lid
      pure $ TokenValue Tablet (NegativeModifier shroud)
    ElderThing -> pure $ TokenValue ElderThing ZeroModifier
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
  , MinusThree
  , MinusFour
  , Skull
  , Skull
  , Skull
  , AutoFail
  , ElderSign
  ]

investigatorDefeat
  :: ( MonadReader env m
     , HasSet DefeatedInvestigatorId env ()
     , HasSet InvestigatorId env ()
     )
  => m [Message]
investigatorDefeat = do
  investigatorIds <- getInvestigatorIds
  defeatedInvestigatorIds <- map unDefeatedInvestigatorId <$> getSetList ()
  if null defeatedInvestigatorIds
    then pure []
    else
      pure
      $ story investigatorIds defeat
      : map DrivenInsane defeatedInvestigatorIds
      <> [ GameOver
         | null
           (setFromList @(HashSet InvestigatorId) investigatorIds
           `difference` setFromList @(HashSet InvestigatorId)
                          defeatedInvestigatorIds
           )
         ]

instance ScenarioRunner env => RunMessage TheUnspeakableOath where
  runMessage msg s@(TheUnspeakableOath attrs) = case msg of
    SetTokensForScenario -> do
      whenM getIsStandalone $ do
        randomToken <- sample (Cultist :| [Tablet, ElderThing])
        push (SetTokens $ standaloneTokens <> [randomToken, randomToken])
      pure s
    Setup -> do
      gatheredCards <- buildEncounterDeck
        [ EncounterSet.TheUnspeakableOath
        , EncounterSet.HastursGift
        , EncounterSet.InhabitantsOfCarcosa
        , EncounterSet.Delusions
        , EncounterSet.DecayAndFilth
        , EncounterSet.AgentsOfHastur
        ]

      westernPatientWing <- genCard =<< sample
        (Locations.asylumHallsWesternPatientWing_168
        :| [Locations.asylumHallsWesternPatientWing_169]
        )

      easternPatientWing <- genCard =<< sample
        (Locations.asylumHallsEasternPatientWing_170
        :| [Locations.asylumHallsEasternPatientWing_171]
        )

      messHall <- genCard Locations.messHall
      kitchen <- genCard Locations.kitchen
      yard <- genCard Locations.yard
      garden <- genCard Locations.garden
      infirmary <- genCard Locations.infirmary
      basementHall <- genCard Locations.basementHall

      setAsideCards <- traverse
        genCard
        [ Assets.danielChesterfield
        , Locations.patientConfinementDrearyCell
        , Locations.patientConfinementDanielsCell
        , Locations.patientConfinementOccupiedCell
        , Locations.patientConfinementFamiliarCell
        ]
      let
        (monsters, deck') =
          partition (`cardMatch` CardWithTrait Monster) (unDeck gatheredCards)
        (lunatics, deck'') =
          partition (`cardMatch` CardWithTrait Lunatic) deck'
        encounterDeck = Deck deck''
      investigatorIds <- getInvestigatorIds
      constanceInterviewed <-
        elem (Recorded $ toCardCode Assets.constanceDumaine)
          <$> getRecordSet VIPsInterviewed
      courageMessages <- if constanceInterviewed
        then concat <$> for
          investigatorIds
          \iid -> do
            deck <- map unDeckCard <$> getList iid
            case deck of
              (x : _) -> do
                courageProxy <- genPlayerCard Assets.courage
                let
                  courage = PlayerCard
                    (courageProxy { pcOriginalCardCode = toCardCode x })
                pure
                  [ DrawCards iid 1 False
                  , InitiatePlayCardAs iid (toCardId x) courage [] False
                  ]
              _ -> error "empty investigator deck"
        else pure []
      theFollowersOfTheSignHaveFoundTheWayForward <- getHasRecord
        TheFollowersOfTheSignHaveFoundTheWayForward

      let
        spawnMessages = map
          (\iid -> chooseOne
            iid
            [ TargetLabel
                (LocationTarget $ toLocationId location)
                [MoveTo (toSource attrs) iid (toLocationId location)]
            | location <- [westernPatientWing, easternPatientWing]
            ]
          )
          investigatorIds
        intro1Or2 = if theFollowersOfTheSignHaveFoundTheWayForward
          then intro1
          else intro2
        tokenToAdd = case scenarioDifficulty attrs of
          Easy -> MinusTwo
          Standard -> MinusThree
          Hard -> MinusFour
          Expert -> MinusFive

      pushAllEnd
        $ [story investigatorIds intro1Or2, story investigatorIds intro3]
        <> courageMessages
        <> [ SetEncounterDeck encounterDeck
           , SetAgendaDeck
           , SetActDeck
           , PlaceLocation westernPatientWing
           , SetLocationLabel
             (toLocationId westernPatientWing)
             "asylumHallsWesternPatientWing"
           , PlaceLocation easternPatientWing
           , SetLocationLabel
             (toLocationId easternPatientWing)
             "asylumHallsEasternPatientWing"
           , PlaceLocation messHall
           , PlaceLocation kitchen
           , PlaceLocation yard
           , PlaceLocation garden
           , PlaceLocation infirmary
           , PlaceLocation basementHall
           , AddToken tokenToAdd
           ]
        <> spawnMessages

      tookTheOnyxClasp <- getHasRecord YouTookTheOnyxClasp
      let
        theReallyBadOnes = if tookTheOnyxClasp
          then Acts.theReallyBadOnesV1
          else Acts.theReallyBadOnesV2

      TheUnspeakableOath <$> runMessage
        msg
        (attrs
        & (setAsideCardsL .~ setAsideCards)
        & (decksL . at LunaticsDeck ?~ map EncounterCard lunatics)
        & (decksL . at MonstersDeck ?~ map EncounterCard monsters)
        & (actStackL
          . at 1
          ?~ [ Acts.arkhamAsylum
             , theReallyBadOnes
             , Acts.planningTheEscape
             , Acts.noAsylum
             ]
          )
        & (agendaStackL
          . at 1
          ?~ [ Agendas.lockedInside
             , Agendas.torturousDescent
             , Agendas.hisDomain
             ]
          )
        )
    ResolveToken _ tokenFace iid -> case tokenFace of
      Skull -> s <$ when (isHardExpert attrs) (push $ DrawAnotherToken iid)
      ElderThing -> do
        monsters <- getSetAsideCardsMatching
          (CardWithType EnemyType <> CardWithTrait Monster)
        case monsters of
          [] -> s <$ push FailSkillTest
          (x : xs) -> do
            monster <- sample (x :| xs)
            s <$ push
              (chooseOne
                iid
                [ Label
                  "Randomly choose an enemy from among the set-aside Monster enemies and place it beneath the act deck without looking at it"
                  [PlaceUnderneath ActDeckTarget [monster]]
                , Label "This test automatically fails" [FailSkillTest]
                ]
              )
      _ -> TheUnspeakableOath <$> runMessage msg attrs
    FailedSkillTest iid _ _ (TokenTarget token) _ _ -> do
      case tokenFace token of
        Skull -> do
          monsters <- getSetAsideCardsMatching
            (CardWithType EnemyType <> CardWithTrait Monster)
          case monsters of
            [] -> pure ()
            (x : xs) -> do
              monster <- sample (x :| xs)
              push (PlaceUnderneath ActDeckTarget [monster])
        Cultist -> push
          $ InvestigatorAssignDamage iid (TokenSource token) DamageAny 0 1
        Tablet ->
          push $ InvestigatorAssignDamage iid (TokenSource token) DamageAny 0 1
        _ -> pure ()
      pure s
    ScenarioResolution NoResolution -> do
      push (ScenarioResolution $ Resolution 1)
      pure . TheUnspeakableOath $ attrs & inResolutionL .~ True
    ScenarioResolution (Resolution n) -> do
      msgs <- investigatorDefeat
      leadInvestigatorId <- getLeadInvestigatorId
      investigatorIds <- getInvestigatorIds
      gainXp <- map (uncurry GainXP) <$> getXp
      constanceSlain <- selectOne
        (VictoryDisplayCardMatch $ cardIs Enemies.constanceDumaine)
      danielWasAlly <- selectAny (assetIs Assets.danielChesterfield)
      danielWasEnemy <- selectAny (enemyIs Enemies.danielChesterfield)

      let
        interludeResult
          | danielWasAlly = DanielSurvived
          | danielWasEnemy = DanielWasPossessed
          | otherwise = DanielDidNotSurvive

      let
        updateSlain =
          [ RecordSetInsert VIPsSlain [toCardCode constance]
          | constance <- maybeToList constanceSlain
          ]
        removeTokens =
          [ RemoveAllTokens Cultist
          , RemoveAllTokens Tablet
          , RemoveAllTokens ElderThing
          ]

      case n of
        1 -> do
          youTookTheOnyxClasp <- getHasRecord YouTookTheOnyxClasp
          claspMessages <- if youTookTheOnyxClasp
            then do
              onyxClasp <- getCampaignStoryCard Assets.claspOfBlackOnyx ()
              pure
                [ RemoveCampaignCardFromDeck
                  (fromJustNote "must have bearer" $ pcBearer onyxClasp)
                  (toCardCode onyxClasp)
                , chooseOne
                  leadInvestigatorId
                  [ TargetLabel
                      (InvestigatorTarget iid)
                      [AddCampaignCardToDeck iid Assets.claspOfBlackOnyx]
                  | iid <- investigatorIds
                  ]
                ]
            else pure []
          pushAll
            $ msgs
            <> [ story investigatorIds resolution1
               , Record TheKingClaimedItsVictims
               ]
            <> gainXp
            <> claspMessages
            <> updateSlain
            <> removeTokens
            <> [AddToken Cultist, AddToken Cultist]
            <> [EndOfGame Nothing]
        2 ->
          pushAll
            $ msgs
            <> [story investigatorIds resolution2]
            <> [Record TheInvestigatorsWereAttackedAsTheyEscapedTheAsylum]
            <> [ SufferTrauma iid 1 0 | iid <- investigatorIds ]
            <> gainXp
            <> updateSlain
            <> removeTokens
            <> [AddToken Tablet, AddToken Tablet]
            <> [EndOfGame (Just $ InterludeStep 2 (Just interludeResult))]
        3 ->
          pushAll
            $ msgs
            <> [story investigatorIds resolution3]
            <> [Record TheInvestigatorsEscapedTheAsylum]
            <> gainXp
            <> updateSlain
            <> removeTokens
            <> [AddToken ElderThing, AddToken ElderThing]
            <> [EndOfGame (Just $ InterludeStep 2 (Just interludeResult))]
        _ -> error "invalid resolution"
      pure s
    _ -> TheUnspeakableOath <$> runMessage msg attrs

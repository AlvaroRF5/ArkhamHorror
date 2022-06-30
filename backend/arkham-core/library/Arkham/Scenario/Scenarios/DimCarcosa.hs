module Arkham.Scenario.Scenarios.DimCarcosa
  ( DimCarcosa(..)
  , dimCarcosa
  ) where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Action qualified as Action
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.CampaignLogKey
import Arkham.Campaigns.ThePathToCarcosa.Helpers
import Arkham.Card
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Helpers.Card
import Arkham.Helpers.Log
import Arkham.Helpers.Query
import Arkham.Helpers.Scenario
import Arkham.Helpers.SkillTest
import Arkham.Id
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Resolution
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.ScenarioLogKey
import Arkham.Scenarios.DimCarcosa.Story
import Arkham.Source
import Arkham.Target
import Arkham.Token
import Arkham.Trait ( Trait (AncientOne, Monster) )
import Arkham.Treachery.Cards qualified as Treacheries

newtype DimCarcosa = DimCarcosa ScenarioAttrs
  deriving anyclass IsScenario
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dimCarcosa :: Difficulty -> DimCarcosa
dimCarcosa difficulty =
  DimCarcosa
    $ baseAttrs "03316" "Dim Carcosa" difficulty
    & locationLayoutL
    ?~ [ ".          darkSpires      ."
       , ".          depthsOfDemhe   ."
       , "dimStreets palaceOfTheKing ruinsOfCarcosa"
       , ".          bleakPlains     ."
       , ".          shoresOfHali    ."
       ]

instance HasModifiersFor DimCarcosa where
  getModifiersFor _ (EnemyTarget eid) (DimCarcosa a) = do
    isHastur <- member eid <$> select (EnemyWithTitle "Hastur")
    knowTheSecret <- remembered KnowTheSecret
    pure $ toModifiers a [ CannotBeDefeated | isHastur && not knowTheSecret ]
  getModifiersFor _ (InvestigatorTarget _) (DimCarcosa a) = do
    pure $ toModifiers a [ CanOnlyBeDefeatedByDamage ]
  getModifiersFor _ _ _ = pure []

instance HasTokenValue DimCarcosa where
  getTokenValue iid tokenFace (DimCarcosa attrs) = case tokenFace of
    Skull -> do
      remainingSanity <- field InvestigatorRemainingSanity iid
      horror <- field InvestigatorHorror iid
      pure $ toTokenValue
        attrs
        Skull
        (if remainingSanity == 0 then 4 else 2)
        horror
    Cultist -> pure $ TokenValue Cultist NoModifier
    Tablet -> pure $ toTokenValue attrs Tablet 3 5
    ElderThing -> pure $ toTokenValue attrs ElderThing 3 5
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
  , MinusFive
  , Skull
  , Skull
  , Skull
  , Cultist
  , Cultist
  , AutoFail
  , ElderSign
  ]

instance RunMessage DimCarcosa where
  runMessage msg s@(DimCarcosa attrs) = case msg of
    SetTokensForScenario -> do
      whenM getIsStandalone $ push $ SetTokens standaloneTokens
      pure s
    StandaloneSetup -> do
      leadInvestigatorId <- getLeadInvestigatorId
      pathOpened <- sample (YouOpenedThePathBelow :| [YouOpenedThePathAbove])
      let
        token =
          if pathOpened == YouOpenedThePathBelow then Tablet else ElderThing

      pushAll
        [ chooseOne
          leadInvestigatorId
          [ Label "Conviction" [RecordCount Conviction 8]
          , Label "Doubt" [RecordCount Doubt 8]
          , Label "Neither" []
          ]
        , Record pathOpened
        , AddToken token
        , AddToken token
        , AddCampaignCardToDeck leadInvestigatorId Enemies.theManInThePallidMask
        ]
      pure s
    Setup -> do
      doubt <- getDoubt
      conviction <- getConviction
      leadInvestigatorId <- getLeadInvestigatorId

      push $ if doubt + conviction <= 5
        then SetupStep 1
        else case compare doubt conviction of
          GT -> SetupStep 2
          LT -> SetupStep 3
          EQ -> chooseOne
            leadInvestigatorId
            [ Label "Use Search For the Stranger (v. II)" [SetupStep 2]
            , Label "Use Search For the Stranger (v. III)" [SetupStep 3]
            ]
      pure s
    SetupStep n -> do
      let
        act2 = case n of
          1 -> Acts.searchForTheStrangerV1
          2 -> Acts.searchForTheStrangerV2
          3 -> Acts.searchForTheStrangerV3
          _ -> error $ "Invalid setup step, got: " <> show n

      investigatorIds <- getInvestigatorIds
      encounterDeck <- buildEncounterDeckExcluding
        [ Enemies.hasturTheKingInYellow
        , Enemies.hasturLordOfCarcosa
        , Enemies.hasturTheTatteredKing
        , Enemies.beastOfAldebaran
        ]
        [ EncounterSet.DimCarcosa
        , EncounterSet.Delusions
        , EncounterSet.CultOfTheYellowSign
        , EncounterSet.InhabitantsOfCarcosa
        , EncounterSet.AgentsOfHastur
        , EncounterSet.StrikingFear
        ]

      shoresOfHali <- genCard Locations.shoresOfHali
      darkSpires <- genCard Locations.darkSpires
      palaceOfTheKing <- genCard Locations.palaceOfTheKing

      (bleakPlains, setAsideBleakPlains) <- sampleWithRest =<< traverse
        genCard
        (Locations.bleakPlainsBleakDesolation
        :| [Locations.bleakPlainsStarsOfAldebaran]
        )
      (ruinsOfCarcosa, setAsideRuinsOfCarcosa) <- sampleWithRest =<< traverse
        genCard
        (Locations.ruinsOfCarcosaTheCoffin
        :| [ Locations.ruinsOfCarcosaInhabitantOfCarcosa
           , Locations.ruinsOfCarcosaAMomentsRest
           ]
        )
      (dimStreets, setAsideDimStreets) <- sampleWithRest =<< traverse
        genCard
        (Locations.dimStreetsMappingTheStreets
        :| [ Locations.dimStreetsTheArchway
           , Locations.dimStreetsTheKingsParade
           ]
        )
      (depthsOfDemhe, setAsideDepthsOfDemhe) <- sampleWithRest =<< traverse
        genCard
        (Locations.depthsOfDemheStepsOfThePalace
        :| [Locations.depthsOfDemheTheHeightOfTheDepths]
        )

      openedThePathBelow <- getHasRecord YouOpenedThePathBelow
      let
        (intro, startingLocation) = if openedThePathBelow
          then (intro1, shoresOfHali)
          else (intro2, darkSpires)

      theManInThePallidMask <- getCampaignStoryCard
        Enemies.theManInThePallidMask

      setAsideCards <- traverse
        genCard
        [ Enemies.hasturTheKingInYellow
        , Enemies.hasturLordOfCarcosa
        , Enemies.hasturTheTatteredKing
        , Enemies.beastOfAldebaran
        ]

      pushAll
        [ story investigatorIds intro
        , SetEncounterDeck encounterDeck
        , SetAgendaDeck
        , SetActDeck
        , PlaceLocation bleakPlains
        , PlaceLocation ruinsOfCarcosa
        , PlaceLocation dimStreets
        , PlaceLocation depthsOfDemhe
        , PlaceLocation palaceOfTheKing
        , PlaceLocation darkSpires
        , PlaceLocation shoresOfHali
        , MoveAllTo (toSource attrs) (toLocationId startingLocation)
        , RemoveFromBearersDeckOrDiscard theManInThePallidMask
        ]
      DimCarcosa <$> runMessage
        msg
        (attrs
        & (setAsideCardsL
          .~ PlayerCard theManInThePallidMask
          : (setAsideCards
            <> setAsideBleakPlains
            <> setAsideRuinsOfCarcosa
            <> setAsideDimStreets
            <> setAsideDepthsOfDemhe
            )
          )
        & (actStackL
          . at 1
          ?~ [Acts.inLostCarcosa, act2, Acts.theKingInTatters]
          )
        & (agendaStackL
          . at 1
          ?~ [ Agendas.madnessCoils
             , Agendas.madnessDrowns
             , Agendas.madnessDies
             ]
          )
        )
    FailedSkillTest iid _ _ (TokenTarget token) _ _ -> do
      when (tokenFace token == Cultist) $ push $ InvestigatorAssignDamage
        iid
        (TokenEffectSource Cultist)
        DamageAny
        0
        (if isEasyStandard attrs then 1 else 2)
      when (tokenFace token == Tablet) $ do
        hasturInPlay <- selectAny $ EnemyWithTitle "Hastur"
        when hasturInPlay $ do
          mlid <- field InvestigatorLocation iid
          for_ mlid $ \lid -> push $ PlaceClues (LocationTarget lid) 1
      pure s
    ResolveToken _ ElderThing iid -> do
      mskillTestSource <- getSkillTestSource
      mskillTestTarget <- getSkillTestTarget
      case (mskillTestSource, mskillTestTarget) of
        (Just (SkillTestSource _ _ _ (Just action)), Just (EnemyTarget eid))
          | action `elem` [Action.Fight, Action.Evade] -> do
            isMonsterOrAncientOne <-
              member eid <$> select
                (EnemyOneOf $ map EnemyWithTrait [Monster, AncientOne])
            when isMonsterOrAncientOne $ push $ LoseActions
              iid
              (TokenEffectSource ElderThing)
              1
        _ -> pure ()
      pure s
    ScenarioResolution res -> do
      investigatorIds <- getInvestigatorIds
      conviction <- getConviction
      doubt <- getDoubt
      gainXp <- map (uncurry GainXP) <$> getXpWithBonus 5
      possessed <- selectList $ InvestigatorWithTreacheryInHand $ TreacheryOneOf $ map treacheryIs [Treacheries.possessionMurderous, Treacheries.possessionTraitorous, Treacheries.possessionTorturous]
      let recordPossessed = RecordSet Possessed (map unInvestigatorId possessed)
      case res of
        NoResolution -> case compare conviction doubt of
          GT -> push $ ScenarioResolution $ Resolution 4
          EQ -> push $ ScenarioResolution $ Resolution 4
          LT -> push $ ScenarioResolution $ Resolution 5
        Resolution 1 -> do
          pushAll $ [story investigatorIds resolution1]
            <> [SufferTrauma iid 2 2 | iid <- investigatorIds]
            <> gainXp
            <> [recordPossessed, EndOfGame Nothing]
        Resolution 2 -> do
          pushAll $ [story investigatorIds resolution2]
            <> [SufferTrauma iid 0 2 | iid <- investigatorIds]
            <> gainXp
            <> [recordPossessed, EndOfGame Nothing]
        Resolution 3 -> do
          pushAll $ [story investigatorIds resolution3]
            <> [SufferTrauma iid 2 0 | iid <- investigatorIds]
            <> gainXp
            <> [recordPossessed, EndOfGame Nothing]
        Resolution 4 -> do
          pushAll $ [story investigatorIds resolution4, Record TheRealmOfCarcosaMergedWithOurOwnAndHasturRulesOverThemBoth]
            <> map DrivenInsane investigatorIds
            <> [GameOver]
        Resolution 5 -> do
          pushAll $ [story investigatorIds resolution5, Record HasturHasYouInHisGrasp]
            <> map DrivenInsane investigatorIds
            <> [GameOver]
        _ -> error "Unhandled resolution"
      pure s
    _ -> DimCarcosa <$> runMessage msg attrs

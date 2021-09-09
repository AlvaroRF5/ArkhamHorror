module Arkham.Types.Scenario.Scenarios.BloodOnTheAltar
  ( BloodOnTheAltar(..)
  , bloodOnTheAltar
  ) where

import Arkham.Prelude

import qualified Arkham.Act.Cards as Acts
import qualified Arkham.Agenda.Cards as Agendas
import qualified Arkham.Asset.Cards as Assets
import qualified Arkham.Enemy.Cards as Enemies
import qualified Arkham.Location.Cards as Locations
import Arkham.Types.AgendaId
import Arkham.Types.CampaignLogKey
import Arkham.Types.Card
import Arkham.Types.Card.EncounterCard
import Arkham.Types.Card.PlayerCard
import Arkham.Types.Classes
import Arkham.Types.Difficulty
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Exception
import Arkham.Types.Helpers
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Name
import Arkham.Types.Resolution
import Arkham.Types.Scenario.Attrs
import Arkham.Types.Scenario.Helpers
import Arkham.Types.Scenario.Runner
import Arkham.Types.Target
import Arkham.Types.Token
import Data.Maybe (fromJust)

newtype BloodOnTheAltarMetadata = BloodOnTheAltarMetadata { sacrifices :: [Card]}
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

newtype BloodOnTheAltar = BloodOnTheAltar (ScenarioAttrs `With` BloodOnTheAltarMetadata)
  deriving stock Generic
  deriving anyclass (IsScenario, HasRecord)
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

bloodOnTheAltar :: Difficulty -> BloodOnTheAltar
bloodOnTheAltar difficulty =
  BloodOnTheAltar . (`with` BloodOnTheAltarMetadata []) $ base
    { scenarioLocationLayout = Just
      [ ". houseInTheReedsHiddenChamber houseInTheReedsHiddenChamber houseInTheReeds houseInTheReeds schoolhouse schoolhouse schoolhouseHiddenChamber schoolhouseHiddenChamber ."
      , "congregationalChurchHiddenChamber congregationalChurchHiddenChamber congregationalChurch congregationalChurch villageCommons  villageCommons osbornsGeneralStore osbornsGeneralStore osbornsGeneralStoreHiddenChamber osbornsGeneralStoreHiddenChamber"
      , ". burnedRuinsHiddenChamber burnedRuinsHiddenChamber burnedRuins burnedRuins bishopsBrook bishopsBrook bishopsBrookHiddenChamber bishopsBrookHiddenChamber ."
      ]
    }
 where
  base = baseAttrs
    "02195"
    "Blood on the Altar"
    [ Agendas.strangeDisappearances
    , Agendas.theOldOnesHunger
    , Agendas.feedTheBeast
    ]
    [Acts.searchingForAnswers, Acts.theChamberOfTheBeast]
    difficulty

bloodOnTheAltarIntro :: Message
bloodOnTheAltarIntro = FlavorText
  (Just "Scenario IV: Blood on the Altar")
  [ "When you finally reach Dunwich, you are\
    \ greeted by Zebulon Whateley and Earl Sawyer,\
    \ another man from the village who had met with\
    \ Dr. Armitage during the incident several months\
    \ ago. “Things ain’t lookin’ too good here,” Earl\
    \ tells you. “Some folk up and went missin’ a few\
    \ nights ago. ‘Dem whippoorwills won’ shut up.\
    \ Dunno what yer doin’ here, but last time you Arkham folk came ‘round\
    \ it was bad news. Very bad news.” His eyes blink rapidly, and he coughs\
    \ and looks away."
  , "“Look, why don’t you rest fer the night an’ look fer whatever it is yer\
    \ looking fer t’morra,” Zebulon chimes in, putting a wrinkled hand on\
    \ your shoulder. You begin to protest, but your aching muscles and weary\
    \ mind won’t allow you to refuse. The elderly man offers to take you in\
    \ for the night, and drives you to his home at the outskirts of Dunwich\
    \ village. The town is disheveled and eerie, and you find yourself wishing\
    \ you hadn’t come here at all. You fall asleep on the ride over and scarcely\
    \ remember anything else from that night."
  , "When you awaken, you find that Zebulon’s house is abandoned, and\
    \ there is no sign of the elderly man, or of Mr. Sawyer. Fearing the worst,\
    \ you head into the village of Dunwich to investigate, hoping to find\
    \ answers."
  ]

instance
  ( HasTokenValue env InvestigatorId
  , HasSet LocationId env ()
  , HasList UnderneathCard env LocationId
  )
  => HasTokenValue env BloodOnTheAltar where
  getTokenValue (BloodOnTheAltar (attrs `With` _)) iid = \case
    Skull -> do
      numLocations <- countM ((null <$>) . getList @UnderneathCard)
        =<< getSetList @LocationId ()
      pure $ toTokenValue attrs Skull (min 4 numLocations) numLocations
    Cultist -> pure $ toTokenValue attrs Cultist 2 4
    Tablet -> pure $ toTokenValue attrs Tablet 2 3
    ElderThing -> pure $ toTokenValue attrs ElderThing 3 3
    otherFace -> getTokenValue attrs iid otherFace

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
  , Cultist
  , Tablet
  , ElderThing
  , AutoFail
  , ElderSign
  ]

findOwner
  :: (MonadReader env m, HasList CampaignStoryCard env ())
  => CardCode
  -> m (Maybe InvestigatorId)
findOwner cardCode = do
  campaignStoryCards <- getList ()
  pure
    $ campaignStoryCardInvestigatorId
    <$> find
          ((== cardCode) . toCardCode . campaignStoryCardPlayerCard)
          campaignStoryCards

getRemoveSacrificedMessages
  :: (MonadReader env m, HasList CampaignStoryCard env ())
  => [CardCode]
  -> m [Message]
getRemoveSacrificedMessages sacrifices = do
  sacrificedOwnerPairs <- catMaybes <$> for
    sacrifices
    (\sacrifice -> do
      mOwner <- findOwner sacrifice
      pure $ (sacrifice, ) <$> mOwner
    )
  pure
    [ RemoveCampaignCardFromDeck owner sacrificed
    | (sacrificed, owner) <- sacrificedOwnerPairs
    ]

getRemoveNecronomicon
  :: ( MonadReader env m
     , HasList CampaignStoryCard env ()
     , HasSet DefeatedInvestigatorId env ()
     )
  => m [Message]
getRemoveNecronomicon = do
  defeatedInvestigatorIds <- map unDefeatedInvestigatorId <$> getSetList ()
  mNecronomiconOwner <- findOwner "02140"
  pure
    [ RemoveCampaignCardFromDeck owner "02140"
    | owner <- maybeToList mNecronomiconOwner
    , owner `elem` defeatedInvestigatorIds
    ]

instance ScenarioRunner env => RunMessage env BloodOnTheAltar where
  runMessage msg s@(BloodOnTheAltar (attrs@ScenarioAttrs {..} `With` metadata@(BloodOnTheAltarMetadata sacrificed)))
    = case msg of
      SetTokensForScenario -> do
        standalone <- getIsStandalone
        s <$ if standalone then push (SetTokens standaloneTokens) else pure ()
      Setup -> do
        let toLocationCard = fmap EncounterCard . genEncounterCard
        investigatorIds <- getInvestigatorIds
        bishopsBrook <- toLocationCard =<< sample
          (Locations.bishopsBrook_202 :| [Locations.bishopsBrook_203])
        burnedRuins <- toLocationCard =<< sample
          (Locations.burnedRuins_204 :| [Locations.burnedRuins_205])
        osbornsGeneralStore <- toLocationCard =<< sample
          (Locations.osbornsGeneralStore_206
          :| [Locations.osbornsGeneralStore_207]
          )
        congregationalChurch <- toLocationCard =<< sample
          (Locations.congregationalChurch_208
          :| [Locations.congregationalChurch_209]
          )
        houseInTheReeds <- toLocationCard =<< sample
          (Locations.houseInTheReeds_210 :| [Locations.houseInTheReeds_211])
        schoolhouse <- toLocationCard =<< sample
          (Locations.schoolhouse_212 :| [Locations.schoolhouse_213])

        oBannionGangHasABoneToPick <- getHasRecordOrStandalone
          OBannionGangHasABoneToPickWithTheInvestigators
          False

        (encounterCardsToPutUnderneath, encounterDeck) <-
          splitAt 3 . unDeck <$> buildEncounterDeckExcluding
            [ Enemies.silasBishop
            , Locations.theHiddenChamber
            , Assets.keyToTheChamber
            ]
            ([ EncounterSet.BloodOnTheAltar
             , EncounterSet.Dunwich
             , EncounterSet.Whippoorwills
             , EncounterSet.Nightgaunts
             , EncounterSet.AncientEvils
             ]
            <> [ EncounterSet.NaomisCrew | oBannionGangHasABoneToPick ]
            )

        theHiddenChamber <- EncounterCard
          <$> genEncounterCard Locations.theHiddenChamber
        keyToTheChamber <- EncounterCard
          <$> genEncounterCard Assets.keyToTheChamber

        cardsToPutUnderneath <-
          shuffleM
          $ keyToTheChamber
          : theHiddenChamber
          : map EncounterCard encounterCardsToPutUnderneath

        professorWarrenRiceKidnapped <- getHasRecordOrStandalone
          ProfessorWarrenRiceWasKidnapped
          True
        drFrancisMorganKidnapped <- getHasRecordOrStandalone
          DrFrancisMorganWasKidnapped
          True
        drHenryArmitageKidnapped <- getHasRecordOrStandalone
          DrHenryArmitageWasKidnapped
          True

        professorWarrenRice <- if professorWarrenRiceKidnapped
          then Just . PlayerCard <$> genPlayerCard Assets.professorWarrenRice
          else pure Nothing
        drFrancisMorgan <- if drFrancisMorganKidnapped
          then Just . PlayerCard <$> genPlayerCard Assets.drFrancisMorgan
          else pure Nothing
        drHenryArmitage <- if drHenryArmitageKidnapped
          then Just . PlayerCard <$> genPlayerCard Assets.drHenryArmitage
          else pure Nothing
        zebulonWhateley <- PlayerCard <$> genPlayerCard Assets.zebulonWhateley
        earlSawyer <- PlayerCard <$> genPlayerCard Assets.earlSawyer

        delayedOnTheirWayToDunwich <- getHasRecordOrStandalone
          TheInvestigatorsWereDelayedOnTheirWayToDunwich
          False

        locations <- drop 1 <$> shuffleM
          [ bishopsBrook
          , burnedRuins
          , osbornsGeneralStore
          , congregationalChurch
          , houseInTheReeds
          , schoolhouse
          ]

        villageCommons <- EncounterCard
          <$> genEncounterCard Locations.villageCommons

        locationIds <- getRandoms

        let
          locationCardPairs = zip locations cardsToPutUnderneath
          potentialSacrifices = [zebulonWhateley, earlSawyer] <> catMaybes
            [professorWarrenRice, drFrancisMorgan, drHenryArmitage]

        pushAll
          $ [ story investigatorIds bloodOnTheAltarIntro
            , SetEncounterDeck (Deck encounterDeck)
            , AddAgenda "02196"
            ]
          <> [ PlaceDoomOnAgenda | delayedOnTheirWayToDunwich ]
          <> [AddAct "02199", PlaceLocation villageCommons]
          <> concat
               [ [ PlaceLocation location
                 , PlaceUnderneath (LocationTarget locationId) [card]
                 ]
               | (locationId, (location, card)) <- zip
                 locationIds
                 locationCardPairs
               ]
          <> [ RevealLocation Nothing (LocationId $ toCardId villageCommons)
             , MoveAllTo (toSource attrs) (LocationId $ toCardId villageCommons)
             ]

        setAsideCards <- traverse
          genCard
          [ Enemies.silasBishop
          , Locations.theHiddenChamber
          , Assets.keyToTheChamber
          , Assets.powderOfIbnGhazi
          ]

        BloodOnTheAltar . (`with` metadata) <$> runMessage
          msg
          (attrs
          & (setAsideCardsL .~ setAsideCards)
          & (deckL ?~ PotentialSacrifices potentialSacrifices)
          )
      ResolveToken _ Tablet iid -> do
        lid <- getId @LocationId iid
        matches <- (== "Hidden Chamber") . nameTitle <$> getName lid
        s <$ when
          (isHardExpert attrs || (isEasyStandard attrs && matches))
          (push $ DrawAnotherToken iid)
      ResolveToken _ ElderThing _ | isHardExpert attrs -> do
        agendaId <-
          fromJustNote "no agenda" . headMay <$> getSetList @AgendaId ()
        s <$ push (PlaceDoom (AgendaTarget agendaId) 1)
      FailedSkillTest iid _ _ (TokenTarget token) _ _ ->
        s <$ case tokenFace token of
          Cultist -> do
            lid <- getId @LocationId iid
            push (PlaceClues (LocationTarget lid) 1)
          ElderThing | isEasyStandard attrs -> do
            agendaId <-
              fromJustNote "no agenda" . headMay <$> getSetList @AgendaId ()
            push (PlaceDoom (AgendaTarget agendaId) 1)
          _ -> pure ()
      ScenarioResolution NoResolution -> do
        leadInvestigatorId <- getLeadInvestigatorId
        agendaId <-
          fromJustNote "no agenda" . headMay <$> getSetList @AgendaId ()
        xp <- getXp
        let
          potentialSacrifices = case scenarioDeck of
            Just (PotentialSacrifices xs) -> xs
            _ -> error "missing deck"
          sacrificedToYogSothoth =
            map toCardCode potentialSacrifices <> map toCardCode sacrificed
        removeSacrificedMessages <- getRemoveSacrificedMessages
          sacrificedToYogSothoth
        removeNecronomicon <- getRemoveNecronomicon
        s <$ pushAll
          ([ chooseOne
               leadInvestigatorId
               [ Run
                 $ [ Continue "Continue"
                   , FlavorText
                     Nothing
                     [ "The cries of the whippoorwills\
                     \ fade into the distance, and the town of Dunwich is filled with\
                     \ an eerie silence. All that can be heard is the dry whistle of the\
                     \ chill wind and the slow rustling of dead leaves. There is no sign\
                     \ of the missing townsfolk, nor will there be ever again."
                     ]
                   , Record TheRitualWasCompleted
                   , PlaceUnderneath (AgendaTarget agendaId) potentialSacrifices
                   ]
                 <> removeSacrificedMessages
                 <> removeNecronomicon
               ]
           ]
          <> [ GainXP iid (n + 2) | (iid, n) <- xp ]
          <> [EndOfGame]
          )
      ScenarioResolution (Resolution 1) -> do
        leadInvestigatorId <- getLeadInvestigatorId
        xp <- getXp
        let sacrificedToYogSothoth = map toCardCode sacrificed
        removeSacrificedMessages <- getRemoveSacrificedMessages
          sacrificedToYogSothoth
        removeNecronomicon <- getRemoveNecronomicon
        s <$ pushAll
          ([ chooseOne
               leadInvestigatorId
               [ Run
                 $ [ Continue "Continue"
                   , FlavorText
                     (Just "Resolution 1")
                     [ "As you land the finishing blow, the creature’s\
                     \ body explodes into hundreds of squirming ropelike\
                     \ appendages, wriggling across the ground and climbing up the\
                     \ walls. You’re so startled that you aren’t fast enough to prevent\
                     \ them from escaping the room. Even so, whatever that creature\
                     \ was, you’re glad it’s now dead."
                     ]
                   , Record TheInvestigatorsPutSilasBishopOutOfHisMisery
                   ]
                 <> removeSacrificedMessages
                 <> removeNecronomicon
               ]
           ]
          <> [ GainXP iid (n + 2) | (iid, n) <- xp ]
          <> [EndOfGame]
          )
      ScenarioResolution (Resolution 2) -> do
        leadInvestigatorId <- getLeadInvestigatorId
        xp <- getXp
        let sacrificedToYogSothoth = map toCardCode sacrificed
        removeSacrificedMessages <- getRemoveSacrificedMessages
          sacrificedToYogSothoth
        s <$ pushAll
          ([ chooseOne
               leadInvestigatorId
               [ Run
                 $ [ Continue "Continue"
                   , FlavorText
                     (Just "Resolution 2")
                     [ "With the creature that once was Silas\
                     \ lashing out at you from its chains, you have little time to\
                     \ react. Knowing that the Necronomicon might have a spell\
                     \ or incantation that could subdue Silas, you fend off the\
                     \ abomination long enough to find a passage that can help.\
                     \ With no time to spare, you recite the Latin incantation,\
                     \ and find that the words come effortlessly to your tongue, as\
                     \ though recalled from an earlier memory. The creature’s body\
                     \ begins to shrink and melt away as the incantation builds, its\
                     \ cries terrifying and haunting. In the end, all that is left is the\
                     \ disfigured corpse of a man—Silas Bishop. You find a silver\
                     \ pendant emblazoned with an odd constellation tucked into\
                     \ his shirt. You take it with you, hoping to find a use for it."
                     ]
                   , Record TheInvestigatorsRestoredSilasBishop
                   ]
                 <> removeSacrificedMessages
               ]
           ]
          <> [ GainXP iid (n + 2) | (iid, n) <- xp ]
          <> [EndOfGame]
          )
      ScenarioResolution (Resolution 3) -> do
        leadInvestigatorId <- getLeadInvestigatorId
        xp <- getXp
        let sacrificedToYogSothoth = map toCardCode sacrificed
        removeSacrificedMessages <- getRemoveSacrificedMessages
          sacrificedToYogSothoth
        removeNecronomicon <- getRemoveNecronomicon
        s <$ pushAll
          ([ chooseOne
               leadInvestigatorId
               [ Run
                 $ [ Continue "Continue"
                   , FlavorText
                     (Just "Resolution 3")
                     [ "With the creature that once was Silas lashing\
                     \ out at you from its chains, you have little time to react.\
                     \ Hoping there is something in the chamber you can use to your\
                     \ advantage, you fend off the abomination long enough to find a\
                     \ journal; many of its passages are written in Latin. It appears\
                     \ to be a handwritten excerpt from the Necronomicon, its\
                     \ purpose unknown. With no time to spare, you recite the\
                     \ incantation, stumbling over the words and feeling your throat\
                     \ tighten with each sentence. The creature’s body begins to\
                     \ shrink and melt away as the incantation continues, its cries\
                     \ terrifying and haunting. In the end, all that is left is a pile of\
                     \ wet and sticky ichor, and a rotten stench."
                     ]
                   , Record TheInvestigatorsBanishedSilasBishop
                   ]
                 <> removeSacrificedMessages
                 <> [RecordSet SacrificedToYogSothoth sacrificedToYogSothoth]
                 <> removeNecronomicon
               ]
           ]
          <> [ GainXP iid (n + 2) | (iid, n) <- xp ]
          <> [EndOfGame]
          )
      AddCardToScenarioDeck card -> case scenarioDeck of
        Just (PotentialSacrifices cards) ->
          pure
            . BloodOnTheAltar
            . (`with` metadata)
            $ attrs
            & deckL
            ?~ PotentialSacrifices (card : cards)
        _ -> throwIO $ InvalidState "incorrect deck"
      UseScenarioSpecificAbility _ _ 1 -> case scenarioDeck of
        Just (PotentialSacrifices []) -> pure s
        Just (PotentialSacrifices cards) -> do
          result <- shuffleM cards
          let
            c = fromJust . headMay $ result
            cards' = drop 1 result
          pure
            . BloodOnTheAltar
            . (`with` BloodOnTheAltarMetadata (c : sacrificed))
            $ attrs
            & deckL
            ?~ PotentialSacrifices cards'
        _ -> throwIO $ InvalidState "incorrect deck"
      _ -> BloodOnTheAltar . (`with` metadata) <$> runMessage msg attrs

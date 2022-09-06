{-# OPTIONS_GHC -Wno-orphans #-}
module Arkham.Treachery where

import Arkham.Prelude

import Arkham.Treachery.Runner
import Arkham.Treachery.Treacheries
import Arkham.Card
import Arkham.Classes
import Arkham.Id

createTreachery :: IsCard a => a -> InvestigatorId -> Treachery
createTreachery a iid =
  lookupTreachery (toCardCode a) iid (TreacheryId $ toCardId a)

instance RunMessage Treachery where
  runMessage msg (Treachery a) = Treachery <$> runMessage msg a

lookupTreachery :: CardCode -> (InvestigatorId -> TreacheryId -> Treachery)
lookupTreachery cardCode = case lookup cardCode allTreacheries of
  Nothing -> error $ "Unknown treachery: " <> show cardCode
  Just (SomeTreacheryCard a) -> \i t -> Treachery $ cbCardBuilder a (i, t)

instance FromJSON Treachery where
  parseJSON v = flip (withObject "Treachery") v $ \o -> do
    cCode :: CardCode <- o .: "cardCode"
    withTreacheryCardCode cCode $ \(_ :: TreacheryCard a) -> Treachery <$> parseJSON @a v

withTreacheryCardCode
  :: CardCode
  -> (forall a. IsTreachery a => TreacheryCard a -> r)
  -> r
withTreacheryCardCode cCode f =
  case lookup cCode allTreacheries of
    Nothing -> error $ "Unknown treachery: " <> show cCode
    Just (SomeTreacheryCard a) -> f a

allTreacheries :: HashMap CardCode SomeTreacheryCard
allTreacheries = mapFromList $ map
  (toFst someTreacheryCardCode)
  [ -- Night of the Zealot
  -- signature
    SomeTreacheryCard coverUp
  , SomeTreacheryCard hospitalDebts
  , SomeTreacheryCard abandonedAndAlone
  -- weakness
  , SomeTreacheryCard amnesia
  , SomeTreacheryCard paranoia
  , SomeTreacheryCard haunted
  , SomeTreacheryCard psychosis
  , SomeTreacheryCard hypochondria
  -- The Midnight Masks
  , SomeTreacheryCard huntingShadow
  , SomeTreacheryCard falseLead
  -- The Devourer Below
  , SomeTreacheryCard umordhothsWrath
  -- Ghouls
  , SomeTreacheryCard graspingHands
  -- Striking Fear
  , SomeTreacheryCard rottingRemains
  , SomeTreacheryCard frozenInFear
  , SomeTreacheryCard dissonantVoices
  -- Ancient Evils
  , SomeTreacheryCard ancientEvils
  -- Chilling Colds
  , SomeTreacheryCard cryptChill
  , SomeTreacheryCard obscuringFog
  -- Dark Cult
  , SomeTreacheryCard mysteriousChanting
  -- Nightgaunts
  , SomeTreacheryCard onWingsOfDarkness
  -- Locked Doors
  , SomeTreacheryCard lockedDoor
  -- Agents of Hastur
  , SomeTreacheryCard theYellowSign
  -- Agents of Yog Sothoth
  , SomeTreacheryCard offerOfPower
  -- Agents of Cthulhu
  , SomeTreacheryCard dreamsOfRlyeh
  -- The Dunwich Legacy
  -- signature
  , SomeTreacheryCard smiteTheWicked
  , SomeTreacheryCard rexsCurse
  , SomeTreacheryCard searchingForIzzie
  , SomeTreacheryCard finalRhapsody
  , SomeTreacheryCard wrackedByNightmares
  -- weakness
  , SomeTreacheryCard indebted
  , SomeTreacheryCard internalInjury
  , SomeTreacheryCard chronophobia
  -- The House Always Wins
  , SomeTreacheryCard somethingInTheDrinks
  , SomeTreacheryCard arousingSuspicions
  -- Sorcery
  , SomeTreacheryCard visionsOfFuturesPast
  , SomeTreacheryCard beyondTheVeil
  -- Bishop's Thralls
  , SomeTreacheryCard lightOfAforgomon
  -- Dunwich
  , SomeTreacheryCard unhallowedCountry
  , SomeTreacheryCard sordidAndSilent
  -- Whippoorwill
  , SomeTreacheryCard eagerForDeath
  -- Bad Luck
  , SomeTreacheryCard cursedLuck
  , SomeTreacheryCard twistOfFate
  -- Beast Thralls
  , SomeTreacheryCard alteredBeast
  -- Naomi's Crew
  , SomeTreacheryCard huntedDown
  -- The Beyond
  , SomeTreacheryCard pushedIntoTheBeyond
  , SomeTreacheryCard terrorFromBeyond
  , SomeTreacheryCard arcaneBarrier
  -- The Miskatonic Museum
  , SomeTreacheryCard shadowSpawned
  , SomeTreacheryCard stalkedInTheDark
  , SomeTreacheryCard passageIntoTheVeil
  , SomeTreacheryCard ephemeralExhibits
  , SomeTreacheryCard slitheringBehindYou
  -- The Essex County Express
  , SomeTreacheryCard acrossSpaceAndTime
  , SomeTreacheryCard clawsOfSteam
  , SomeTreacheryCard brokenRails
  -- Blood on the Altar
  , SomeTreacheryCard kidnapped
  , SomeTreacheryCard psychopompsSong
  , SomeTreacheryCard strangeSigns
  , SomeTreacheryCard rottingRemainsBloodOnTheAltar
  -- Undimensioned and Unseen
  , SomeTreacheryCard toweringBeasts
  , SomeTreacheryCard ruinAndDestruction
  , SomeTreacheryCard attractingAttention
  , SomeTreacheryCard theCreaturesTracks
  -- Where Doom Awaits
  , SomeTreacheryCard ritesHowled
  , SomeTreacheryCard spacesBetween
  , SomeTreacheryCard vortexOfTime
  -- Lost in Time and Space
  , SomeTreacheryCard collapsingReality
  , SomeTreacheryCard wormhole
  , SomeTreacheryCard vastExpanse
  -- The Path to Carcosa
  -- signature
  , SomeTreacheryCard shellShock
  , SomeTreacheryCard starsOfHyades
  , SomeTreacheryCard angeredSpirits
  , SomeTreacheryCard crisisOfIdentity
  -- weakness
  , SomeTreacheryCard overzealous
  , SomeTreacheryCard drawingTheSign
  -- The Last King
  , SomeTreacheryCard fineDining
  , SomeTreacheryCard toughCrowd
  -- Delusions
  , SomeTreacheryCard whispersInYourHeadDismay
  , SomeTreacheryCard whispersInYourHeadDread
  , SomeTreacheryCard whispersInYourHeadAnxiety
  , SomeTreacheryCard whispersInYourHeadDoubt
  , SomeTreacheryCard descentIntoMadness
  -- Byakhee
  , SomeTreacheryCard huntedByByakhee
  -- Evil Portants
  , SomeTreacheryCard blackStarsRise
  , SomeTreacheryCard spiresOfCarcosa
  , SomeTreacheryCard twistedToHisWill
  -- Hauntings
  , SomeTreacheryCard spiritsTorment
  -- Hastur's Gift
  , SomeTreacheryCard danceOfTheYellowKing
  -- Cult of the Yellow Sign
  , SomeTreacheryCard theKingsEdict
  -- Decay and Filth
  , SomeTreacheryCard oozeAndFilth
  , SomeTreacheryCard corrosion
  -- The Stranger
  , SomeTreacheryCard markedByTheSign
  , SomeTreacheryCard thePaleMaskBeckons
  -- Echoes of the Past
  , SomeTreacheryCard ledAstray
  , SomeTreacheryCard theCultsSearch
  -- The Unspeakable Oath
  , SomeTreacheryCard straitjacket
  , SomeTreacheryCard giftOfMadnessPity
  , SomeTreacheryCard giftOfMadnessMisery
  , SomeTreacheryCard wallsClosingIn
  -- A Phantom of Truth
  , SomeTreacheryCard twinSuns
  , SomeTreacheryCard deadlyFate
  , SomeTreacheryCard torturousChords
  , SomeTreacheryCard frozenInFearAPhantomOfTruth
  , SomeTreacheryCard lostSoul
  -- The Pallid Mask
  , SomeTreacheryCard eyesInTheWalls
  , SomeTreacheryCard theShadowBehindYou
  , SomeTreacheryCard thePitBelow
  -- Black Stars Rise
  , SomeTreacheryCard crashingFloods
  , SomeTreacheryCard worldsMerge
  -- Dim Carcosa
  , SomeTreacheryCard dismalCurse
  , SomeTreacheryCard realmOfMadness
  , SomeTreacheryCard theFinalAct
  , SomeTreacheryCard possessionTraitorous
  , SomeTreacheryCard possessionTorturous
  , SomeTreacheryCard possessionMurderous
  -- Forgotten Age
  -- signature
  , SomeTreacheryCard boughtInBlood
  , SomeTreacheryCard callOfTheUnknown
  , SomeTreacheryCard caughtRedHanded
  , SomeTreacheryCard voiceOfTheMessenger
  -- weaknesses
  , SomeTreacheryCard thePriceOfFailure
  , SomeTreacheryCard doomed
  , SomeTreacheryCard accursedFate
  , SomeTreacheryCard theBellTolls
  -- Rainforest
  , SomeTreacheryCard overgrowth
  , SomeTreacheryCard voiceOfTheJungle
  -- Serpents
  , SomeTreacheryCard snakeBite
  -- Expedition
  , SomeTreacheryCard lostInTheWilds
  , SomeTreacheryCard lowOnSupplies
  -- Agents of Yig
  , SomeTreacheryCard curseOfYig
  -- Guardians of Time
  , SomeTreacheryCard arrowsFromTheTrees
  -- Deadly Trap
  , SomeTreacheryCard finalMistake
  , SomeTreacheryCard entombed
  -- Temporal Flux
  , SomeTreacheryCard aTearInTime
  , SomeTreacheryCard lostInTime
  -- Forgotten Ruins
  , SomeTreacheryCard illOmen
  , SomeTreacheryCard ancestralFear
  , SomeTreacheryCard deepDark
  -- Pnakotic Brotherhood
  , SomeTreacheryCard shadowed
  -- Poison
  , SomeTreacheryCard creepingPoison
  , SomeTreacheryCard poisoned
  -- Edge of the Earth
  -- signature
  , SomeTreacheryCard theHarbinger
  -- Return to the Night of the Zealot
  -- Return to the Gathering
  , SomeTreacheryCard theZealotsSeal
  -- Return to the Midnight Masks
  , SomeTreacheryCard maskedHorrors
  -- Return to the Devourer Below
  , SomeTreacheryCard vaultOfEarthlyDemise
  , SomeTreacheryCard umordhothsHunger
  -- Ghouls of Umordhoth
  , SomeTreacheryCard chillFromBelow
  -- The Devourer's Cult
  , SomeTreacheryCard chillFromBelow
  -- Nathaniel Cho
  , SomeTreacheryCard selfDestructive
  -- Stella Clark
  , SomeTreacheryCard calledByTheMists
  , SomeTreacheryCard atychiphobia
  -- Curse of the Rougarou
  , SomeTreacheryCard cursedSwamp
  , SomeTreacheryCard spectralMist
  , SomeTreacheryCard draggedUnder
  , SomeTreacheryCard ripplesOnTheSurface
  , SomeTreacheryCard curseOfTheRougarou
  , SomeTreacheryCard onTheProwl
  , SomeTreacheryCard beastOfTheBayou
  , SomeTreacheryCard insatiableBloodlust
  -- Carnevale of Horror
  , SomeTreacheryCard massHysteria
  , SomeTreacheryCard lostInVenice
  , SomeTreacheryCard watchersGaze
  , SomeTreacheryCard chaosInTheWater
  , SomeTreacheryCard mesmerize
  , SomeTreacheryCard abduction
  , SomeTreacheryCard acridMiasma
  ]

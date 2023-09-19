module Arkham.Tarot where

import Arkham.Prelude

import Data.List.NonEmpty qualified as NE

tarotDeck :: NonEmpty TarotCardArcana
tarotDeck = NE.fromList [minBound .. maxBound]

data TarotReading = Chaos | Balance | Choice | Destiny
  deriving stock (Show, Eq, Ord, Bounded, Enum, Generic, Data)
  deriving anyclass (ToJSON, FromJSON)

data TarotCardFacing = Upright | Reversed
  deriving stock (Show, Eq, Ord, Bounded, Enum, Generic, Data)
  deriving anyclass (ToJSON, FromJSON)

data TarotCard = TarotCard TarotCardFacing TarotCardArcana
  deriving stock (Show, Eq, Ord, Generic, Data)
  deriving anyclass (ToJSON, FromJSON)

toTarotArcana :: TarotCard -> TarotCardArcana
toTarotArcana (TarotCard _ arcana) = arcana

data TarotCardArcana
  = TheFool0
  | TheMagicianI
  | TheHighPriestessII
  | TheEmpressIII
  | TheEmperorIV
  | TheHierophantV
  | TheLoversVI
  | TheChariotVII
  | StengthVIII
  | TheHermitIX
  | WheelOfFortuneX
  | JusticeXI
  | TheHangedManXII
  | DeathXIII
  | TemperanceXIV
  | TheDevilXV
  | TheTowerXVI
  | TheMoonXVIII
  | TheStarXVII
  | TheSunXIX
  | JudgementXX
  | TheWorldXXI
  deriving stock (Show, Eq, Ord, Bounded, Enum, Generic, Data)
  deriving anyclass (ToJSON, FromJSON)

module Arkham.Strategy where

import Arkham.Prelude
import Arkham.Card.CardDef
import Arkham.Id
import Arkham.Target
import Arkham.Zone

data DamageStrategy
  = DamageAny
  | DamageAssetsFirst
  | DamageFirst CardDef
  | SingleTarget
  | DamageEvenly
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

data ZoneReturnStrategy = PutBackInAnyOrder | ShuffleBackIn | PutBack
    deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

data FoundCardsStrategy = PlayFound InvestigatorId Int | DrawFound InvestigatorId Int | DeferSearchedToTarget Target | ReturnCards
    deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

data ChosenCardStrategy = LeaveChosenCard | RemoveChosenCardFromGame
    deriving stock (Show, Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

fromTopOfDeck :: Int -> (Zone, ZoneReturnStrategy)
fromTopOfDeck n = (FromTopOfDeck n, ShuffleBackIn)

fromDeck :: (Zone, ZoneReturnStrategy)
fromDeck = (FromDeck, ShuffleBackIn)


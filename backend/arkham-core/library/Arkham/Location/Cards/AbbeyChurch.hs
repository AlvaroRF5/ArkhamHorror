module Arkham.Location.Cards.AbbeyChurch
  ( abbeyChurch
  , AbbeyChurch(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Types ( Field (AgendaSequence) )
import Arkham.Agenda.Sequence qualified as AS
import Arkham.Classes
import Arkham.Cost
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message hiding ( RevealLocation )
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype AbbeyChurch = AbbeyChurch LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

abbeyChurch :: LocationCard AbbeyChurch
abbeyChurch = locationWith
  AbbeyChurch
  Cards.abbeyChurch
  3
  (PerPlayer 1)
  Square
  [Equals, T, Heart, Hourglass, Moon]
  (costToEnterUnrevealedL
  .~ GroupClueCost (PerPlayer 3) (LocationWithTitle "Broken Steps")
  )

anyDifferent :: Eq a => [a] -> Bool
anyDifferent [] = False
anyDifferent [_] = False
anyDifferent (x : y : xs) = if x /= y then True else anyDifferent (y : xs)

instance HasModifiersFor AbbeyChurch where
  getModifiersFor _ (LocationTarget lid) (AbbeyChurch a) | toId a == lid = do
    as <- map AS.agendaStep <$> selectAgg pure AgendaSequence AnyAgenda
    pure $ toModifiers a [ ShroudModifier 2 | anyDifferent as ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities AbbeyChurch where
  getAbilities (AbbeyChurch attrs) =
    withBaseAbilities attrs $ if locationRevealed attrs
      then
        [ mkAbility attrs 1
          $ ForcedAbility
          $ RevealLocation Timing.After Anyone
          $ LocationWithId
          $ toId attrs
        ]
      else []

instance RunMessage AbbeyChurch where
  runMessage msg l@(AbbeyChurch attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      let
        titles =
          [ "Chœur Gothique"
          , "Knight's Hall"
          , "Cloister"
          , "Chapel of St. Aubert"
          , "Abbey Tower"
          ]
      pushAll $ map (PlaceLocationMatching . CardWithTitle) titles
      pure l
    _ -> AbbeyChurch <$> runMessage msg attrs

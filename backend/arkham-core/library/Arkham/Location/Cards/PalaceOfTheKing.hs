module Arkham.Location.Cards.PalaceOfTheKing
  ( palaceOfTheKing
  , PalaceOfTheKing(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Enemy.Attrs ( Field (..) )
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message hiding ( EnemyDamage )
import Arkham.Projection
import Arkham.ScenarioLogKey
import Arkham.Scenarios.DimCarcosa.Helpers
import Arkham.Story.Cards qualified as Story
import Arkham.Target

newtype PalaceOfTheKing = PalaceOfTheKing LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

palaceOfTheKing :: LocationCard PalaceOfTheKing
palaceOfTheKing = locationWith
  PalaceOfTheKing
  Cards.palaceOfTheKing
  2
  (PerPlayer 3)
  Star
  [Triangle, Diamond]
  (canBeFlippedL .~ True)

instance HasModifiersFor PalaceOfTheKing where
  getModifiersFor _ (LocationTarget lid) (PalaceOfTheKing attrs)
    | lid == toId attrs = do
      mHastur <- selectOne $ EnemyWithTitle "Hastur"
      modifiers' <- case mHastur of
        Nothing -> pure [CannotBeFlipped]
        Just hastur -> do
          n <- getPlayerCountValue (PerPlayer 5)
          hasEnoughDamage <- fieldP EnemyDamage (>= n) hastur
          pure [ CannotBeFlipped | not hasEnoughDamage ]
      pure $ toModifiers attrs modifiers'
  getModifiersFor _ _ _ = pure []

instance RunMessage PalaceOfTheKing where
  runMessage msg l@(PalaceOfTheKing attrs) = case msg of
    Flip iid _ target | isTarget attrs target -> do
      readStory iid (toId attrs) Story.hastursEnd
      pure . PalaceOfTheKing $ attrs & canBeFlippedL .~ False
    ResolveStory _ story' | story' == Story.hastursEnd -> do
      push $ Remember KnowTheSecret
      pure l
    _ -> PalaceOfTheKing <$> runMessage msg attrs

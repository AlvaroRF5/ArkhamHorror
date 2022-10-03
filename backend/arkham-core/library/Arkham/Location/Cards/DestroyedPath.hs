module Arkham.Location.Cards.DestroyedPath
  ( destroyedPath
  , DestroyedPath(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards ( destroyedPath )
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message hiding ( RevealLocation )
import Arkham.SkillType
import Arkham.Source
import Arkham.Timing qualified as Timing

newtype DestroyedPath = DestroyedPath LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

destroyedPath :: LocationCard DestroyedPath
destroyedPath = location DestroyedPath Cards.destroyedPath 3 (Static 0)

instance HasAbilities DestroyedPath where
  getAbilities (DestroyedPath attrs) =
    withBaseAbilities attrs $ if locationRevealed attrs
      then
        [ mkAbility attrs 1
        $ ForcedAbility
        $ RevealLocation Timing.After You
        $ LocationWithId
        $ toId attrs
        , withTooltip
          "{action}: _Investigate_. If you succeed, instead of discovering clues, remove 1 doom from Destroyed Path."
        $ restrictedAbility attrs 2 Here
        $ ActionAbility (Just Action.Investigate)
        $ ActionCost 1
        ]
      else []

instance RunMessage DestroyedPath where
  runMessage msg l@(DestroyedPath attrs) = case msg of
    UseCardAbility _ source 1 _ _ | isSource attrs source -> do
      amount <- getPlayerCountValue (PerPlayer 1)
      l <$ push (PlaceDoom (toTarget attrs) amount)
    UseCardAbility iid source 2 _ _ | isSource attrs source -> l <$ push
      (Investigate
        iid
        (toId attrs)
        (AbilitySource source 2)
        Nothing
        SkillIntellect
        False
      )
    Successful (Action.Investigate, _) _ (AbilitySource source 2) _ _
      | isSource attrs source -> l <$ push (RemoveDoom (toTarget attrs) 1)
    _ -> DestroyedPath <$> runMessage msg attrs

module Arkham.Location.Cards.Yard
  ( yard
  , Yard(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Investigator.Attrs (Field(..))
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Message
import Arkham.Modifier
import Arkham.Projection
import Arkham.ScenarioLogKey
import Arkham.SkillTest
import Arkham.Source
import Arkham.Target

newtype Yard = Yard LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

yard :: LocationCard Yard
yard = location Yard Cards.yard 1 (PerPlayer 1) Diamond [Circle, Plus]

instance HasModifiersFor Yard where
  getModifiersFor _ (LocationTarget lid) (Yard attrs) | lid == toId attrs = do
    mskillTestSource <- getSkillTestSource
    case mskillTestSource of
      Just (SkillTestSource iid _ source (Just Action.Investigate))
        | isSource attrs source -> do
          horror <- field InvestigatorHorror iid
          pure $ toModifiers
            attrs
            [ ShroudModifier horror | locationRevealed attrs ]
      _ -> pure []
  getModifiersFor _ _ _ = pure []

instance HasAbilities Yard where
  getAbilities (Yard attrs) = withBaseAbilities
    attrs
    [ restrictedAbility attrs 1 (Here <> NoCluesOnThis)
      $ ActionAbility Nothing
      $ Costs [ActionCost 1, DamageCost (toSource attrs) YouTarget 1]
    | locationRevealed attrs
    ]

instance RunMessage Yard where
  runMessage msg l@(Yard attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      l <$ push (Remember IncitedAFightAmongstThePatients)
    _ -> Yard <$> runMessage msg attrs

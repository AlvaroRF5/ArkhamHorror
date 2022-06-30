module Arkham.Location.Cards.DimStreetsMappingTheStreets
  ( dimStreetsMappingTheStreets
  , DimStreetsMappingTheStreets(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.DamageEffect
import Arkham.GameValue
import Arkham.Game.Helpers
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher hiding (NonAttackDamageEffect)
import Arkham.Message
import Arkham.SkillType
import Arkham.Scenarios.DimCarcosa.Helpers
import Arkham.Story.Cards qualified as Story
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype DimStreetsMappingTheStreets = DimStreetsMappingTheStreets LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dimStreetsMappingTheStreets :: LocationCard DimStreetsMappingTheStreets
dimStreetsMappingTheStreets = locationWith
  DimStreetsMappingTheStreets
  Cards.dimStreetsMappingTheStreets
  2
  (PerPlayer 1)
  Diamond
  [Square, Equals, Star]
  ((canBeFlippedL .~ True) . (revealedL .~ True))

instance HasAbilities DimStreetsMappingTheStreets where
  getAbilities (DimStreetsMappingTheStreets a) = withBaseAbilities
    a
    [ mkAbility a 1 $ ForcedAbility $ DiscoveringLastClue
        Timing.After
        You
        (LocationWithId $ toId a)
    ]

instance RunMessage DimStreetsMappingTheStreets where
  runMessage msg l@(DimStreetsMappingTheStreets attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ LoseActions iid source 1
      pure l
    Flip iid _ target | isTarget attrs target -> do
      readStory iid (toId attrs) Story.mappingTheStreets
      pure . DimStreetsMappingTheStreets $ attrs & canBeFlippedL .~ False
    ResolveStory iid story' | story' == Story.mappingTheStreets -> do
      hastur <- selectJust $ EnemyWithTitle "Hastur"
      n <- getPlayerCountValue (PerPlayer 1)
      pushAll
        [ BeginSkillTest
          iid
          (toSource attrs)
          (InvestigatorTarget iid)
          Nothing
          SkillIntellect
          3
        , EnemyDamage hastur iid (toSource attrs) StoryCardDamageEffect n
        ]
      pure l
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source -> do
        push $ InvestigatorAssignDamage iid source DamageAny 0 n
        pure l
    _ -> DimStreetsMappingTheStreets <$> runMessage msg attrs

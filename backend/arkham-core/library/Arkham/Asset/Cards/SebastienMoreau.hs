module Arkham.Asset.Cards.SebastienMoreau
  ( sebastienMoreau
  , SebastienMoreau(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Story.Cards qualified as Story
import Arkham.Asset.Runner
import Arkham.Card
import Arkham.Card.EncounterCard
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype SebastienMoreau = SebastienMoreau AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sebastienMoreau :: AssetCard SebastienMoreau
sebastienMoreau = asset SebastienMoreau Cards.sebastienMoreau

instance HasAbilities SebastienMoreau where
  getAbilities (SebastienMoreau a) =
    [ restrictedAbility a 1 OnSameLocation $ ActionAbility Nothing $ ActionCost
      1
    , mkAbility a 2
      $ ForcedAbility
      $ LastClueRemovedFromAsset Timing.When
      $ AssetWithId
      $ toId a
    ]

instance RunMessage SebastienMoreau where
  runMessage msg a@(SebastienMoreau attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ push
      (BeginSkillTest iid source (toTarget attrs) Nothing SkillWillpower 3)
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        modifiers <- getModifiers source (InvestigatorTarget iid)
        a <$ when
          (assetClues attrs > 0 && CannotTakeControlOfClues `notElem` modifiers)
          (pushAll [RemoveClues (toTarget attrs) 1, GainClues iid 1])
    UseCardAbility _ source _ 2 _ | isSource attrs source -> do
      a <$ push
        (ReadStory
        $ EncounterCard
        $ lookupEncounterCard Story.theFirstShow
        $ toCardId attrs
        )
    _ -> SebastienMoreau <$> runMessage msg attrs

module Arkham.Asset.Cards.IshimaruHaruko
  ( ishimaruHaruko
  , IshimaruHaruko(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Matcher
import Arkham.SkillType
import Arkham.Story.Cards qualified as Story
import Arkham.Timing qualified as Timing

newtype IshimaruHaruko = IshimaruHaruko AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ishimaruHaruko :: AssetCard IshimaruHaruko
ishimaruHaruko = asset IshimaruHaruko Cards.ishimaruHaruko

instance HasAbilities IshimaruHaruko where
  getAbilities (IshimaruHaruko a) =
    [ restrictedAbility
        a
        1
        (OnSameLocation <> InvestigatorExists
          (You <> HandWith (LengthIs $ AtLeast $ Static 6))
        )
      $ ActionAbility Nothing
      $ ActionCost 1
    , mkAbility a 2
      $ ForcedAbility
      $ LastClueRemovedFromAsset Timing.When
      $ AssetWithId
      $ toId a
    ]

instance RunMessage IshimaruHaruko where
  runMessage msg a@(IshimaruHaruko attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> a <$ push
      (beginSkillTest iid source (toTarget attrs) SkillWillpower 2)
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        modifiers <- getModifiers (InvestigatorTarget iid)
        a <$ when
          (assetClues attrs > 0 && CannotTakeControlOfClues `notElem` modifiers)
          (pushAll [RemoveClues (toTarget attrs) 1, GainClues iid 1])
    UseCardAbility iid source 2 _ _ | isSource attrs source -> do
      a <$ push (ReadStory iid Story.thePattern)
    _ -> IshimaruHaruko <$> runMessage msg attrs

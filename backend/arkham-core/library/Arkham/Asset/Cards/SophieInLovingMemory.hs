module Arkham.Asset.Cards.SophieInLovingMemory
  ( sophieInLovingMemory
  , SophieInLovingMemory(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Card
import Arkham.Card.PlayerCard
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Modifier
import Arkham.Target

newtype SophieInLovingMemory = SophieInLovingMemory AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sophieInLovingMemory :: AssetCard SophieInLovingMemory
sophieInLovingMemory = assetWith
  SophieInLovingMemory
  Cards.sophieInLovingMemory
  (canLeavePlayByNormalMeansL .~ False)

instance HasAbilities SophieInLovingMemory where
  getAbilities (SophieInLovingMemory x) =
    [ restrictedAbility
        x
        1
        (OwnsThis <> DuringSkillTest (YourSkillTest AnySkillTest))
      $ FastAbility
      $ DirectDamageCost (toSource x) You 1
    , restrictedAbility
        x
        2
        (OwnsThis <> InvestigatorExists
          (You <> InvestigatorWithDamage (AtLeast $ Static 5))
        )
      $ ForcedAbility AnyWindow
    ]

instance RunMessage SophieInLovingMemory where
  runMessage msg a@(SophieInLovingMemory attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ push
        (skillTestModifier attrs (InvestigatorTarget iid) (AnySkillValue 2))
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      a <$ push (Flip (toSource attrs) (toTarget attrs))
    Flip _ target | isTarget attrs target -> do
      let
        sophieItWasAllMyFault = PlayerCard
          $ lookupPlayerCard Cards.sophieItWasAllMyFault (toCardId attrs)
        markId = fromJustNote "invalid" (assetController attrs)
      a <$ pushAll [ReplaceInvestigatorAsset markId sophieItWasAllMyFault]
    _ -> SophieInLovingMemory <$> runMessage msg attrs

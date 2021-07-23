module Arkham.Types.Asset.Cards.SophieInLovingMemory
  ( sophieInLovingMemory
  , SophieInLovingMemory(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Card
import Arkham.Types.Card.PlayerCard
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Query
import Arkham.Types.Target

newtype SophieInLovingMemory = SophieInLovingMemory AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sophieInLovingMemory :: AssetCard SophieInLovingMemory
sophieInLovingMemory = assetWith
  SophieInLovingMemory
  Cards.sophieInLovingMemory
  (canLeavePlayByNormalMeansL .~ False)

ability :: AssetAttrs -> Ability
ability attrs = mkAbility attrs 2 ForcedAbility & abilityLimitL .~ NoLimit

instance HasCount DamageCount env InvestigatorId => HasActions env SophieInLovingMemory where
  getActions iid _ (SophieInLovingMemory attrs) = whenOwnedBy attrs iid $ do
    damageCount <- unDamageCount <$> getCount iid
    pure [ UseAbility iid (ability attrs) | damageCount >= 5 ]

instance HasModifiersFor env SophieInLovingMemory

instance (HasQueue env, HasModifiersFor env ()) => RunMessage env SophieInLovingMemory where
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
        markId = fromJustNote "invalid" (assetInvestigator attrs)
      a <$ pushAll [ReplaceInvestigatorAsset markId sophieItWasAllMyFault]
    _ -> SophieInLovingMemory <$> runMessage msg attrs

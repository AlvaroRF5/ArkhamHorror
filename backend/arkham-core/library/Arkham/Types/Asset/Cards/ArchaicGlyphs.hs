module Arkham.Types.Asset.Cards.ArchaicGlyphs
  ( archaicGlyphs
  , ArchaicGlyphs(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Uses
import Arkham.Types.CampaignLogKey
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Window

newtype ArchaicGlyphs = ArchaicGlyphs AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

archaicGlyphs :: AssetCard ArchaicGlyphs
archaicGlyphs = asset ArchaicGlyphs Cards.archaicGlyphs

instance HasAbilities env ArchaicGlyphs where
  getAbilities iid NonFast (ArchaicGlyphs attrs) | ownedBy attrs iid = pure
    [ mkAbility attrs 1 $ ActionAbility Nothing $ SkillIconCost 1 $ singleton
        SkillIntellect
    ]
  getAbilities iid window (ArchaicGlyphs attrs) = getAbilities iid window attrs

instance HasModifiersFor env ArchaicGlyphs

instance (HasQueue env, HasModifiersFor env ()) => RunMessage env ArchaicGlyphs where
  runMessage msg a@(ArchaicGlyphs attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AddUses (toTarget attrs) Secret 1)
    AddUses target Secret _ | isTarget attrs target -> do
      let ownerId = fromJustNote "must be owned" $ assetInvestigator attrs
      attrs' <- runMessage msg attrs
      ArchaicGlyphs attrs' <$ when
        (useCount (assetUses attrs') >= 3)
        (pushAll
          [ Discard (toTarget attrs)
          , TakeResources ownerId 5 False
          , Record YouHaveTranslatedTheGlyphs
          ]
        )
    _ -> ArchaicGlyphs <$> runMessage msg attrs

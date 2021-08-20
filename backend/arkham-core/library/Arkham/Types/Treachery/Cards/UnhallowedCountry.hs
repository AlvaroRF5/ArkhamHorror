module Arkham.Types.Treachery.Cards.UnhallowedCountry
  ( UnhallowedCountry(..)
  , unhallowedCountry
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers

newtype UnhallowedCountry = UnhallowedCountry TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

unhallowedCountry :: TreacheryCard UnhallowedCountry
unhallowedCountry = treachery UnhallowedCountry Cards.unhallowedCountry

instance (HasSet Trait env AssetId, HasId (Maybe OwnerId) env AssetId) => HasModifiersFor env UnhallowedCountry where
  getModifiersFor _ (InvestigatorTarget iid) (UnhallowedCountry attrs) =
    pure $ toModifiers
      attrs
      [ CannotPlay [(AssetType, singleton Ally)]
      | treacheryOnInvestigator iid attrs
      ]
  getModifiersFor _ (AssetTarget aid) (UnhallowedCountry attrs) = do
    traits <- getSet @Trait aid
    miid <- fmap unOwnerId <$> getId aid
    pure $ case miid of
      Just iid -> toModifiers
        attrs
        [ Blank | treacheryOnInvestigator iid attrs && Ally `member` traits ]
      Nothing -> []
  getModifiersFor _ _ _ = pure []

instance HasAbilities env UnhallowedCountry where
  getAbilities i window (UnhallowedCountry attrs) = getAbilities i window attrs

instance RunMessage env UnhallowedCountry where
  runMessage msg t@(UnhallowedCountry attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AttachTreachery treacheryId $ InvestigatorTarget iid)
    ChooseEndTurn iid | treacheryOnInvestigator iid attrs -> t <$ push
      (RevelationSkillTest iid (TreacherySource treacheryId) SkillWillpower 3)
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> t <$ push (Discard $ toTarget attrs)
    _ -> UnhallowedCountry <$> runMessage msg attrs

module Arkham.Treachery.Cards.CrisisOfIdentity
  ( crisisOfIdentity
  , CrisisOfIdentity(..)
  ) where

import Arkham.Prelude

import Arkham.Card.CardDef
import Arkham.Classes
import Arkham.ClassSymbol
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Target
import Arkham.Treachery.Attrs
import Arkham.Treachery.Cards qualified as Cards

newtype CrisisOfIdentity = CrisisOfIdentity TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor m, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

crisisOfIdentity :: TreacheryCard CrisisOfIdentity
crisisOfIdentity = treachery CrisisOfIdentity Cards.crisisOfIdentity

instance RunMessage CrisisOfIdentity where
  runMessage msg t@(CrisisOfIdentity attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      role <- field InvestigatorClass iid
      assets <- selectList
        (AssetControlledBy (InvestigatorWithId iid)
        <> AssetWithClass role
        <> DiscardableAsset
        )
      events <- selectList
        (EventControlledBy (InvestigatorWithId iid) <> EventWithClass role)
      skills <- selectList
        (SkillControlledBy (InvestigatorWithId iid) <> SkillWithClass role)
      pushAll
        $ [ Discard $ AssetTarget aid | aid <- assets ]
        <> [ Discard $ EventTarget eid | eid <- events ]
        <> [ Discard $ SkillTarget sid | sid <- skills ]
        <> [DiscardTopOfDeck iid 1 (Just $ toTarget attrs)]
      pure t
    DiscardedTopOfDeck iid [card] target | isTarget attrs target -> do
      t <$ push
        (SetRole iid $ fromMaybe Neutral $ cdClassSymbol $ toCardDef card)
    _ -> CrisisOfIdentity <$> runMessage msg attrs

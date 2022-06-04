module Arkham.Treachery.Cards.FinalRhapsody where

import Arkham.Prelude

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Message
import Arkham.RequestedTokenStrategy
import Arkham.Token
import Arkham.Treachery.Attrs

newtype FinalRhapsody = FinalRhapsody TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor m, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

finalRhapsody :: TreacheryCard FinalRhapsody
finalRhapsody = treachery FinalRhapsody Cards.finalRhapsody

instance RunMessage FinalRhapsody where
  runMessage msg t@(FinalRhapsody attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      t <$ push (RequestTokens source (Just iid) 5 SetAside)
    RequestedTokens source (Just iid) tokens | isSource attrs source -> do
      let damageCount = count ((`elem` [Skull, AutoFail]) . tokenFace) tokens
      t <$ pushAll
        [ chooseOne iid [Continue ("Take " <> tshow damageCount <> " damage")]
        , InvestigatorAssignDamage iid source DamageAny damageCount damageCount
        , ResetTokens source
        ]
    _ -> FinalRhapsody <$> runMessage msg attrs

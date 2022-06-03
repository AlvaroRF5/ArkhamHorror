module Arkham.Treachery.Cards.ThePaleMaskBeckons
  ( thePaleMaskBeckons
  , ThePaleMaskBeckons(..)
  ) where

import Arkham.Prelude

import Arkham.Enemy.Cards qualified as Cards
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Attack
import Arkham.Card
import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.Treachery.Attrs
import Arkham.Treachery.Helpers
import Arkham.Treachery.Runner

newtype ThePaleMaskBeckons = ThePaleMaskBeckons TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

thePaleMaskBeckons :: TreacheryCard ThePaleMaskBeckons
thePaleMaskBeckons = treachery ThePaleMaskBeckons Cards.thePaleMaskBeckons

instance TreacheryRunner env => RunMessage ThePaleMaskBeckons where
  runMessage msg t@(ThePaleMaskBeckons attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      mTheManInThePallidMask <- selectOne $ enemyIs Cards.theManInThePallidMask
      t <$ case mTheManInThePallidMask of
        Just enemy -> do
          iids <- getInvestigatorIds
          pushAll $ map (\i -> EnemyAttack i enemy DamageAny RegularAttack) iids
        Nothing -> do
          enemy <- getCampaignStoryCard Cards.theManInThePallidMask ()
          pushAll
            [ RemoveFromBearersDeckOrDiscard enemy
            , DrewPlayerEnemy iid (PlayerCard enemy)
            ]
    _ -> ThePaleMaskBeckons <$> runMessage msg attrs

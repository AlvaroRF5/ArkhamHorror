module Arkham.Treachery.Cards.DaemonicPiping (
  daemonicPiping,
  DaemonicPiping (..),
)
where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Helpers.Card
import Arkham.Matcher
import Arkham.Message
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype DaemonicPiping = DaemonicPiping TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

daemonicPiping :: TreacheryCard DaemonicPiping
daemonicPiping = treachery DaemonicPiping Cards.daemonicPiping

instance RunMessage DaemonicPiping where
  runMessage msg t@(DaemonicPiping attrs) = case msg of
    Revelation _ (isSource attrs -> True) -> do
      mPiperOfAzathoth <- selectOne $ enemyIs Enemies.piperOfAzathoth
      case mPiperOfAzathoth of
        Just piperOfAzathoth -> do
          investigators <-
            selectList
              $ InvestigatorAt
              $ LocationMatchAny
                [ locationWithEnemy piperOfAzathoth
                , ConnectedTo (locationWithEnemy piperOfAzathoth)
                ]
          pushAll $ [assignHorror investigator attrs 1 | investigator <- investigators]
        Nothing -> push $ PlaceTreachery (toId attrs) TreacheryNextToAgenda
      pure t
    AfterRevelation _ tid | tid == toId attrs -> do
      daemonicPipings <- selectList $ treacheryIs Cards.daemonicPiping
      when (length daemonicPipings >= 3) $ do
        piperOfAzathoth <- findJustCard (`cardMatch` cardIs Enemies.piperOfAzathoth)
        createPiperOfAzathoth <- createEnemyEngagedWithPrey_ piperOfAzathoth
        pushAll
          $ map (Discard (toSource attrs) . toTarget) daemonicPipings
          <> [createPiperOfAzathoth]
      pure t
    _ -> DaemonicPiping <$> runMessage msg attrs

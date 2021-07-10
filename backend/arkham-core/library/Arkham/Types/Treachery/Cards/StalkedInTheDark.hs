module Arkham.Types.Treachery.Cards.StalkedInTheDark
  ( stalkedInTheDark
  , StalkedInTheDark(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype StalkedInTheDark = StalkedInTheDark TreacheryAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

stalkedInTheDark :: TreacheryCard StalkedInTheDark
stalkedInTheDark = treachery StalkedInTheDark Cards.stalkedInTheDark

instance HasModifiersFor env StalkedInTheDark

instance HasActions env StalkedInTheDark where
  getActions i window (StalkedInTheDark attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env StalkedInTheDark where
  runMessage msg t@(StalkedInTheDark attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      mHuntingHorrorId <- fmap unStoryEnemyId <$> getId (CardCode "02141")
      case mHuntingHorrorId of
        Just eid -> do
          lid <- getId @LocationId iid
          iids <- getSetList @InvestigatorId lid
          t <$ pushAll
            ([Ready (EnemyTarget eid), EnemyEngageInvestigator eid iid]
            <> [ EnemyAttack iid' eid | iid' <- iids ]
            )
        Nothing -> t <$ pushAll [Surge iid source, Discard $ toTarget attrs]
    _ -> StalkedInTheDark <$> runMessage msg attrs

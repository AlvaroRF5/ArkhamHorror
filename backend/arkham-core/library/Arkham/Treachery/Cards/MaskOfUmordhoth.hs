module Arkham.Treachery.Cards.MaskOfUmordhoth where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Id
import qualified Arkham.Keyword as Keyword
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Target
import Arkham.Trait
import qualified Arkham.Treachery.Cards as Cards
import Arkham.Treachery.Helpers
import Arkham.Treachery.Runner

newtype MaskOfUmordhoth = MaskOfUmordhoth TreacheryAttrs
  deriving anyclass (IsTreachery, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

maskOfUmordhoth :: TreacheryCard MaskOfUmordhoth
maskOfUmordhoth = treachery MaskOfUmordhoth Cards.maskOfUmordhoth

instance HasModifiersFor MaskOfUmordhoth where
  getModifiersFor _ (EnemyTarget eid) (MaskOfUmordhoth attrs)
    | treacheryOnEnemy eid attrs = do
      isUnique <- member eid <$> select UniqueEnemy
      let keyword = if isUnique then Keyword.Retaliate else Keyword.Aloof
      pure $ toModifiers attrs [HealthModifier 2, AddKeyword keyword]
  getModifiersFor _ _ _ = pure []

instance RunMessage MaskOfUmordhoth where
  runMessage msg t@(MaskOfUmordhoth attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      enemies <- selectList $ FarthestEnemyFrom iid $ EnemyWithTrait Cultist
      case enemies of
        [] -> pushAll
          [ FindAndDrawEncounterCard
            iid
            (CardWithType EnemyType <> CardWithTrait Cultist)
          , Revelation iid source
          ]
        eids -> push $ chooseOrRunOne
          iid
          [ AttachTreachery treacheryId (EnemyTarget eid) | eid <- eids ]
      pure t
    _ -> MaskOfUmordhoth <$> runMessage msg attrs

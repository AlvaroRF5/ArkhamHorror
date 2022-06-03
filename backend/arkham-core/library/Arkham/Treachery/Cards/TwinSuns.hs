module Arkham.Treachery.Cards.TwinSuns
  ( twinSuns
  , TwinSuns(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Treachery.Attrs
import qualified Arkham.Treachery.Cards as Cards
import Arkham.Treachery.Runner

newtype TwinSuns = TwinSuns TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

twinSuns :: TreacheryCard TwinSuns
twinSuns = treachery TwinSuns Cards.twinSuns

instance TreacheryRunner env => RunMessage TwinSuns where
  runMessage msg t@(TwinSuns attrs) = case msg of
    Revelation iid source | isSource attrs source -> t <$ pushAll
      [ RevelationSkillTest iid source SkillIntellect 4
      , Discard $ toTarget attrs
      ]
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source -> do
        agenda <- selectJust AnyAgenda
        t <$ push
          (chooseOne
            iid
            [ Label
              "Remove 1 doom from the current agenda"
              [RemoveDoom (AgendaTarget agenda) 1]
            , Label
              "Take 1 horror for each point you failed by"
              [InvestigatorAssignDamage iid source DamageAny 0 n]
            ]
          )
    _ -> TwinSuns <$> runMessage msg attrs

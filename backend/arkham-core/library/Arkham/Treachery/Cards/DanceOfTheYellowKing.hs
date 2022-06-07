module Arkham.Treachery.Cards.DanceOfTheYellowKing
  ( danceOfTheYellowKing
  , DanceOfTheYellowKing(..)
  ) where

import Arkham.Prelude

import Arkham.Attack
import Arkham.Classes
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.SkillType
import Arkham.Target
import Arkham.Trait
import Arkham.Treachery.Runner
import Arkham.Treachery.Cards qualified as Cards

newtype DanceOfTheYellowKing = DanceOfTheYellowKing TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

danceOfTheYellowKing :: TreacheryCard DanceOfTheYellowKing
danceOfTheYellowKing =
  treachery DanceOfTheYellowKing Cards.danceOfTheYellowKing

instance RunMessage DanceOfTheYellowKing where
  runMessage msg t@(DanceOfTheYellowKing attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      anyLunatics <- selectAny (EnemyWithTrait Lunatic)
      t <$ if anyLunatics
        then push (RevelationSkillTest iid source SkillWillpower 3)
        else push (Surge iid source)
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        lunatics <- selectList (NearestEnemy $ EnemyWithTrait Lunatic)
        mlid <- field InvestigatorLocation iid
        for_ mlid $ \lid -> push $ chooseOrRunOne
          iid
          [ TargetLabel
              (EnemyTarget eid)
              [ MoveUntil lid (EnemyTarget eid)
              , EnemyEngageInvestigator eid iid
              , EnemyWillAttack iid eid DamageAny RegularAttack
              ]
          | eid <- lunatics
          ]
        pure t
    _ -> DanceOfTheYellowKing <$> runMessage msg attrs

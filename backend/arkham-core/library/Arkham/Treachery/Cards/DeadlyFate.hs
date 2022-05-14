module Arkham.Treachery.Cards.DeadlyFate
  ( deadlyFate
  , DeadlyFate(..)
  ) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Treachery.Attrs
import qualified Arkham.Treachery.Cards as Cards
import Arkham.Treachery.Runner

newtype DeadlyFate = DeadlyFate TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

deadlyFate :: TreacheryCard DeadlyFate
deadlyFate = treachery DeadlyFate Cards.deadlyFate

instance TreacheryRunner env => RunMessage env DeadlyFate where
  runMessage msg t@(DeadlyFate attrs) = case msg of
    Revelation iid source | isSource attrs source -> t <$ pushAll
      [ RevelationSkillTest iid source SkillWillpower 3
      , Discard $ toTarget attrs
      ]
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> t
      <$ push (DiscardEncounterUntilFirst source $ CardWithType EnemyType)
    RequestedEncounterCard source mcard | isSource attrs source -> do
      iid <- selectJust You
      case mcard of
        Nothing ->
          t <$ push (InvestigatorAssignDamage iid source DamageAny 0 1)
        Just c -> do
          -- tricky, we must create an enemy that has been discaded, have it
          -- attack,  and then remove it
          -- This technically means we have an enemy at no location
          pushAll
            [ FocusCards [EncounterCard c]
            , chooseOne
              iid
              [ Label "Draw enemy" [InvestigatorDrewEncounterCard iid c]
              , Label "That enemy attacks you (from the discard pile)" [] -- EnemyAttack iid eid DamageAny]
              ]
            , UnfocusCards
            ]
          pure t
    _ -> DeadlyFate <$> runMessage msg attrs

module Arkham.Act.Cards.LeadingTheWay
  ( LeadingTheWay(..)
  , leadingTheWay
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Attrs
import Arkham.Act.Cards qualified as Cards
import Arkham.Act.Helpers
import Arkham.Act.Runner
import Arkham.Classes
import Arkham.Criteria
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Resolution
import Arkham.Target

newtype LeadingTheWay = LeadingTheWay ActAttrs
  deriving anyclass IsAct
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

leadingTheWay :: ActCard LeadingTheWay
leadingTheWay = act (3, A) LeadingTheWay Cards.leadingTheWay Nothing

instance Query LocationMatcher env => HasModifiersFor env LeadingTheWay where
  getModifiersFor _ (LocationTarget lid) (LeadingTheWay attrs) = do
    isBlockedPassage <- member lid
      <$> select (locationIs Locations.blockedPassage)
    pure $ toModifiers attrs [ Blank | isBlockedPassage ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities LeadingTheWay where
  getAbilities (LeadingTheWay a) =
    [ restrictedAbility
          a
          1
          (EachUndefeatedInvestigator $ InvestigatorAt $ locationIs
            Locations.blockedPassage
          )
        $ Objective
        $ ForcedAbility AnyWindow
    ]

instance ActRunner env => RunMessage env LeadingTheWay where
  runMessage msg a@(LeadingTheWay attrs) = case msg of
    UseCardAbility _ (isSource attrs -> True) _ 1 _ -> do
      push (AdvanceAct (toId attrs) (toSource attrs) AdvancedWithOther)
      pure a
    AdvanceAct aid _ _ | aid == toId attrs && onSide B attrs -> do
      push $ ScenarioResolution $ Resolution 2
      pure a
    _ -> LeadingTheWay <$> runMessage msg attrs

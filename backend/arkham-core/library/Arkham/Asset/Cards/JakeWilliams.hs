module Arkham.Asset.Cards.JakeWilliams
  ( jakeWilliams
  , JakeWilliams(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner hiding (RevealLocation)
import Arkham.Cost
import Arkham.Criteria
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Matcher
import Arkham.Projection
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype JakeWilliams = JakeWilliams AssetAttrs
  deriving anyclass IsAsset
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

jakeWilliams :: AssetCard JakeWilliams
jakeWilliams = ally JakeWilliams Cards.jakeWilliams (3, 2)

instance HasModifiersFor JakeWilliams where
  getModifiersFor _ (InvestigatorTarget iid) (JakeWilliams a)
    | controlledBy a iid = do
      actions <- field InvestigatorActionsTaken iid
      pure $ toModifiers a $ do
        action <- [Action.Move, Action.Investigate]
        guard $ action `notElem` actions
        pure $ ActionDoesNotCauseAttacksOfOpportunity action
  getModifiersFor _ _ _ = pure []

instance HasAbilities JakeWilliams where
  getAbilities (JakeWilliams a) =
    [ restrictedAbility a 1 OwnsThis $ ReactionAbility
        (OrWindowMatcher
          [ RevealLocation Timing.After You Anywhere
          , PutLocationIntoPlay Timing.After You Anywhere
          ]
        )
        (ExhaustCost (toTarget a))
    ]

instance RunMessage JakeWilliams where
  runMessage msg a@(JakeWilliams attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      push $ DrawCards iid 1 False
      pure a
    _ -> JakeWilliams <$> runMessage msg attrs

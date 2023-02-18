module Arkham.Investigator.Cards.AshcanPete
  ( AshcanPete(..)
  , ashcanPete
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Assets
import Arkham.Cost
import Arkham.Criteria
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Matcher hiding ( FastPlayerWindow )
import Arkham.Message
import Arkham.Modifier
import Arkham.Target

newtype AshcanPete = AshcanPete InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ashcanPete :: InvestigatorCard AshcanPete
ashcanPete = investigatorWith
  AshcanPete
  Cards.ashcanPete
  Stats
    { health = 6
    , sanity = 5
    , willpower = 4
    , intellect = 2
    , combat = 2
    , agility = 3
    }
  (startsWithL .~ [Assets.duke])

instance HasAbilities AshcanPete where
  getAbilities (AshcanPete x) =
    [ limitedAbility (PlayerLimit PerRound 1) $ restrictedAbility
        x
        1
        (Self <> AssetExists (AssetControlledBy You <> AssetExhausted) <> Negate
          (SelfHasModifier ControlledAssetsCannotReady)
        )
        (FastAbility $ HandDiscardCost 1 AnyCard)
    ]

instance HasTokenValue AshcanPete where
  getTokenValue iid ElderSign (AshcanPete attrs) | iid == toId attrs =
    pure $ TokenValue ElderSign (PositiveModifier 2)
  getTokenValue _ token _ = pure $ TokenValue token mempty

instance RunMessage AshcanPete where
  runMessage msg i@(AshcanPete attrs) = case msg of
    ResolveToken _drawnToken ElderSign iid | iid == toId attrs -> do
      mduke <- selectOne $ assetIs Assets.duke
      for_ mduke $ push . Ready . AssetTarget
      pure i
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      targets <- selectListMap
        AssetTarget
        (AssetControlledBy You <> AssetExhausted)
      push $ chooseOne
        iid
        [ TargetLabel target [Ready target] | target <- targets ]
      pure i
    _ -> AshcanPete <$> runMessage msg attrs

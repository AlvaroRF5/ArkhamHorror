module Arkham.Asset.Cards.JimsTrumpet (
  JimsTrumpet (..),
  jimsTrumpet,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.ChaosToken
import Arkham.Damage
import Arkham.Helpers.Investigator
import Arkham.Investigator.Types (Field (..))
import Arkham.Matcher
import Arkham.Placement
import Arkham.Projection
import Arkham.Timing qualified as Timing

newtype JimsTrumpet = JimsTrumpet AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

jimsTrumpet :: AssetCard JimsTrumpet
jimsTrumpet = asset JimsTrumpet Cards.jimsTrumpet

instance HasAbilities JimsTrumpet where
  getAbilities (JimsTrumpet x) =
    [ restrictedAbility
        x
        1
        ( ControlsThis
            <> InvestigatorExists
              ( HealableInvestigator (toSource x) HorrorType
                  $ AnyInvestigator
                    [InvestigatorAt YourLocation, InvestigatorAt ConnectedLocation]
              )
        )
        $ ReactionAbility
          (RevealChaosToken Timing.When Anyone (ChaosTokenFaceIs Skull))
          (ExhaustCost $ toTarget x)
    ]

instance RunMessage JimsTrumpet where
  runMessage msg a@(JimsTrumpet attrs@AssetAttrs {..}) = case msg of
    UseCardAbility _ source 1 _ _ | isSource attrs source ->
      case assetPlacement of
        InPlayArea controllerId -> do
          locationId <-
            fieldMap
              InvestigatorLocation
              (fromJustNote "must be at a location")
              controllerId
          investigatorIdsWithHeal <-
            getInvestigatorsWithHealHorror attrs 1
              $ AnyInvestigator
                [ colocatedWith controllerId
                , InvestigatorAt (AccessibleFrom $ LocationWithId locationId)
                ]

          push
            $ chooseOne
              controllerId
              [ targetLabel iid [healHorror]
              | (iid, healHorror) <- investigatorIdsWithHeal
              ]
          pure a
        _ -> error "Invalid call"
    _ -> JimsTrumpet <$> runMessage msg attrs

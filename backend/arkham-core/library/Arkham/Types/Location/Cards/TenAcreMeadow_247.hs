module Arkham.Types.Location.Cards.TenAcreMeadow_247
  ( tenAcreMeadow_247
  , TenAcreMeadow_247(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards (tenAcreMeadow_247)
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Exception
import Arkham.Types.Game.Helpers
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Message
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Trait
import Arkham.Types.Window

newtype TenAcreMeadow_247 = TenAcreMeadow_247 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

tenAcreMeadow_247 :: LocationCard TenAcreMeadow_247
tenAcreMeadow_247 = location
  TenAcreMeadow_247
  Cards.tenAcreMeadow_247
  2
  (Static 3)
  Diamond
  [Circle, Triangle, Plus]

ability :: LocationAttrs -> Ability
ability attrs =
  mkAbility (toSource attrs) 1 (FastAbility Free)
    & (abilityLimitL .~ GroupLimit PerGame 1)

instance ActionRunner env => HasAbilities env TenAcreMeadow_247 where
  getAbilities iid window@(Window Timing.When FastPlayerWindow) (TenAcreMeadow_247 attrs)
    = withBaseAbilities iid window attrs $ do
      investigatorsWithClues <- notNull <$> locationInvestigatorsWithClues attrs
      anyAbominations <- notNull <$> locationEnemiesWithTrait attrs Abomination
      pure
        [ locationAbility (ability attrs)
        | investigatorsWithClues && anyAbominations
        ]
  getAbilities iid window (TenAcreMeadow_247 attrs) =
    getAbilities iid window attrs

instance LocationRunner env => RunMessage env TenAcreMeadow_247 where
  runMessage msg l@(TenAcreMeadow_247 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      investigatorsWithClues <- locationInvestigatorsWithClues attrs
      abominations <- locationEnemiesWithTrait attrs Abomination
      when
        (null investigatorsWithClues || null abominations)
        (throwIO $ InvalidState "should not have been able to use this ability")
      l <$ pushAll
        [ chooseOne
            iid
            [ Label
              "Place clue on Abomination"
              [ chooseOne
                  iid
                  [ TargetLabel
                      (EnemyTarget eid)
                      [ PlaceClues (EnemyTarget eid) 1
                      , InvestigatorSpendClues iid 1
                      ]
                  | eid <- abominations
                  ]
              ]
            , Label "Do not place clue on Abomination" []
            ]
        | iid <- investigatorsWithClues
        ]
    _ -> TenAcreMeadow_247 <$> runMessage msg attrs

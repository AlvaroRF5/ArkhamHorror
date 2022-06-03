module Arkham.Location.Cards.TenAcreMeadow_247
  ( tenAcreMeadow_247
  , TenAcreMeadow_247(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Location.Cards qualified as Cards (tenAcreMeadow_247)
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Exception
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Target
import Arkham.Trait

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

instance HasAbilities TenAcreMeadow_247 where
  getAbilities (TenAcreMeadow_247 attrs) = withBaseAbilities
    attrs
    [ restrictedAbility
          attrs
          1
          (Here
          <> InvestigatorExists
               (InvestigatorAt YourLocation <> InvestigatorWithAnyClues)
          <> EnemyCriteria
               (EnemyExists
               $ EnemyAt YourLocation
               <> EnemyWithTrait Abomination
               )
          )
          (FastAbility Free)
        & (abilityLimitL .~ GroupLimit PerGame 1)
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage TenAcreMeadow_247 where
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

module Arkham.Location.Cards.WhateleyRuins_250
  ( whateleyRuins_250
  , WhateleyRuins_250(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Exception
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Investigator.Types ( Field (..) )
import Arkham.Location.Cards qualified as Cards ( whateleyRuins_250 )
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Trait

newtype WhateleyRuins_250 = WhateleyRuins_250 LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

whateleyRuins_250 :: LocationCard WhateleyRuins_250
whateleyRuins_250 =
  location WhateleyRuins_250 Cards.whateleyRuins_250 3 (PerPlayer 2)

instance HasModifiersFor WhateleyRuins_250 where
  getModifiersFor (InvestigatorTarget iid) (WhateleyRuins_250 attrs) =
    pure $ toModifiers
      attrs
      [ SkillModifier SkillWillpower (-1) | iid `on` attrs ]
  getModifiersFor _ _ = pure []

instance HasAbilities WhateleyRuins_250 where
  getAbilities (WhateleyRuins_250 attrs) =
    withBaseAbilities attrs
      $ [ restrictedAbility
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

instance RunMessage WhateleyRuins_250 where
  runMessage msg l@(WhateleyRuins_250 attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      investigatorWithCluePairs <-
        selectWithField InvestigatorClues
        $ investigatorAt (toId attrs)
        <> InvestigatorWithAnyClues
      abominations <-
        map EnemyTarget <$> locationEnemiesWithTrait attrs Abomination
      when
        (null investigatorWithCluePairs || null abominations)
        (throwIO $ InvalidState "should not have been able to use this ability")
      let
        placeClueOnAbomination iid' = chooseOne
          iid'
          [ TargetLabel
              target
              [PlaceClues target 1, InvestigatorSpendClues iid' 1]
          | target <- abominations
          ]

      push $ chooseOne
        iid
        [ targetLabel iid'
          $ placeClueOnAbomination iid'
          : [ chooseOne
                iid'
                [ Label "Spend a second clue" [placeClueOnAbomination iid']
                , Label "Do not spend a second clue" []
                ]
            | clueCount > 1
            ]
          <> [ chooseOne
                 iid'
                 [ Label "Spend a third clue" [placeClueOnAbomination iid']
                 , Label "Do not spend a third clue" []
                 ]
             | clueCount > 2
             ]
        | (iid', clueCount) <- investigatorWithCluePairs
        ]
      pure l
    _ -> WhateleyRuins_250 <$> runMessage msg attrs

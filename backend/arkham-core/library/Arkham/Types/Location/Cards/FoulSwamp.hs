module Arkham.Types.Location.Cards.FoulSwamp
  ( FoulSwamp(..)
  , foulSwamp
  ) where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.ScenarioLogKey
import Arkham.Types.Trait

newtype FoulSwamp = FoulSwamp Attrs
  deriving newtype (Show, ToJSON, FromJSON)

foulSwamp :: FoulSwamp
foulSwamp = FoulSwamp $ baseAttrs
  "81016"
  (Name "Foul Swamp" Nothing)
  EncounterSet.CurseOfTheRougarou
  2
  (Static 0)
  Hourglass
  [Equals, Square, Triangle, Diamond]
  [Unhallowed, Bayou]

instance HasModifiersFor env FoulSwamp where
  getModifiersFor _ (InvestigatorTarget iid) (FoulSwamp attrs)
    | iid `member` locationInvestigators attrs = pure
    $ toModifiers attrs [CannotHealHorror, CannotCancelHorror]
  getModifiersFor _ _ _ = pure []

ability :: InvestigatorId -> Attrs -> Ability
ability iid attrs = base { abilityMetadata = Just (IntMetadata 0) }
 where
  base = mkAbility
    (toSource attrs)
    1
    (ActionAbility Nothing $ Costs
      [ ActionCost 1
      , UpTo 3 (HorrorCost (toSource attrs) (InvestigatorTarget iid) 1)
      ]
    )

instance ActionRunner env => HasActions env FoulSwamp where
  getActions iid NonFast (FoulSwamp attrs@Attrs {..}) | locationRevealed =
    withBaseActions iid NonFast attrs $ pure
      [ ActivateCardAbilityAction iid (ability iid attrs)
      | iid `member` locationInvestigators
      ]
  getActions i window (FoulSwamp attrs) = getActions i window attrs

instance LocationRunner env => RunMessage env FoulSwamp where
  runMessage msg l@(FoulSwamp attrs) = case msg of
    PayForCardAbility iid source meta@(Just (IntMetadata n)) 1
      | isSource attrs source -> if n == 3
        then runMessage (UseCardAbility iid source meta 1 NoPayment) l
        else do
          unshiftMessage $ chooseOne
            iid
            [ Run
              [ InvestigatorAssignDamage iid (toSource attrs) 0 1
              , PayForCardAbility iid source (Just (IntMetadata $ n + 1)) 1
              ]
            , Label
              ("Test with +" <> tshow n <> " Willpower")
              [UseCardAbility iid source meta 1 NoPayment]
            ]
          pure l
    UseCardAbility iid source (Just (IntMetadata n)) 1 _
      | isSource attrs source -> l <$ unshiftMessages
        [ CreateSkillTestEffect
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillWillpower n])
          source
          (InvestigatorTarget iid)
        , BeginSkillTest iid source (toTarget attrs) Nothing SkillWillpower 7
        ]
    PassedSkillTest _ _ source _ _ | isSource attrs source ->
      l <$ unshiftMessage (Remember FoundAnAncientBindingStone)
    _ -> FoulSwamp <$> runMessage msg attrs

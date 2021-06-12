module Arkham.Types.Location.Cards.StepsOfYhagharl
  ( stepsOfYhagharl
  , StepsOfYhagharl(..)
  )
where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Card.EncounterCard
import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.Window

newtype StepsOfYhagharl = StepsOfYhagharl LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

stepsOfYhagharl :: LocationId -> StepsOfYhagharl
stepsOfYhagharl = StepsOfYhagharl . baseAttrs
  "02327"
  "Steps of Y'hagharl"
  EncounterSet.LostInTimeAndSpace
  3
  (PerPlayer 1)
  Plus
  [Diamond, Moon]
  [Otherworld, Extradimensional]

instance HasModifiersFor env StepsOfYhagharl where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env StepsOfYhagharl where
  getActions iid (WhenWouldLeave You lid) (StepsOfYhagharl attrs)
    | iid `on` attrs = pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility (toSource attrs) 1 ForcedAbility)
      | lid == locationId attrs
      ]
  getActions iid window (StepsOfYhagharl attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env StepsOfYhagharl where
  runMessage msg l@(StepsOfYhagharl attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      encounterDiscard <- map unDiscardedEncounterCard <$> getList ()
      let
        mMadnessCard = find (member Madness . getTraits) encounterDiscard
        revelationMsgs = case mMadnessCard of
          Nothing -> []
          Just madnessCard ->
            [ RemoveFromEncounterDiscard madnessCard
            , InvestigatorDrewEncounterCard iid madnessCard
            ]
      unshiftMessages revelationMsgs
      StepsOfYhagharl <$> runMessage msg attrs
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      l <$ unshiftMessage
        (BeginSkillTest
          iid
          source
          (InvestigatorTarget iid)
          Nothing
          SkillWillpower
          2
        )
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        replaceMessageMatching (== MoveFrom iid (toId attrs)) (const [])
        replaceMessageMatching
          (\case
            Will (MoveTo iid' _) | iid == iid' -> True
            _ -> False
          )
          (const [])
        l <$ replaceMessageMatching
          (\case
            MoveTo iid' _ | iid == iid' -> True
            _ -> False
          )
          (const [ShuffleBackIntoEncounterDeck $ toTarget attrs])
    _ -> StepsOfYhagharl <$> runMessage msg attrs

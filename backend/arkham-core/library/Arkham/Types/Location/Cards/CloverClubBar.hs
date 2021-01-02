{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Location.Cards.CloverClubBar
  ( cloverClubBar
  , CloverClubBar(..)
  )
where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Game.Helpers
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.ScenarioLogKey
import Arkham.Types.Trait

newtype CloverClubBar = CloverClubBar Attrs
  deriving newtype (Show, ToJSON, FromJSON)

cloverClubBar :: CloverClubBar
cloverClubBar = CloverClubBar $ baseAttrs
  "02072"
  (LocationName "Clover Club Bar" Nothing)
  EncounterSet.TheHouseAlwaysWins
  3
  (Static 0)
  Square
  [Triangle, Circle]
  [CloverClub]

instance HasModifiersFor env CloverClubBar where
  getModifiersFor = noModifiersFor

ability :: Attrs -> Ability
ability attrs = (mkAbility
                  (toSource attrs)
                  1
                  (ActionAbility Nothing $ Costs [ActionCost 1, ResourceCost 2]
                  )
                )
  { abilityLimit = PlayerLimit PerGame 1
  }

instance ActionRunner env => HasActions env CloverClubBar where
  getActions iid NonFast (CloverClubBar attrs@Attrs {..}) | locationRevealed =
    withBaseActions iid NonFast attrs $ do
      step <- unActStep . getStep <$> ask
      pure
        [ ActivateCardAbilityAction iid (ability attrs)
        | iid `member` locationInvestigators && step == 1
        ]
  getActions iid window (CloverClubBar attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env CloverClubBar where
  runMessage msg l@(CloverClubBar attrs@Attrs {..}) = case msg of
    UseCardAbility iid source _ 1 | isSource attrs source && locationRevealed ->
      l <$ unshiftMessages
        [ SpendResources iid 2
        , GainClues iid 2
        , DrawCards iid 2 False
        , Remember $ HadADrink iid
        ]
    _ -> CloverClubBar <$> runMessage msg attrs

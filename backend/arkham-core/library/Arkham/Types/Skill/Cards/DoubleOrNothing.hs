{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Skill.Cards.DoubleOrNothing
  ( doubleOrNothing
  , DoubleOrNothing(..)
  )
where

import Arkham.Import

import Arkham.Types.Game.Helpers
import Arkham.Types.Skill.Attrs
import Arkham.Types.Skill.Runner

newtype DoubleOrNothing = DoubleOrNothing Attrs
  deriving newtype (Show, ToJSON, FromJSON)

doubleOrNothing :: InvestigatorId -> SkillId -> DoubleOrNothing
doubleOrNothing iid uuid = DoubleOrNothing $ baseAttrs iid uuid "02026"

instance HasModifiersFor env DoubleOrNothing where
  getModifiersFor _ SkillTestTarget (DoubleOrNothing attrs) =
    pure $ toModifiers attrs [DoubleDifficulty, DoubleSuccess]
  getModifiersFor _ _ _ = pure []

instance HasActions env DoubleOrNothing where
  getActions iid window (DoubleOrNothing attrs) = getActions iid window attrs

instance SkillRunner env => RunMessage env DoubleOrNothing where
  runMessage msg (DoubleOrNothing attrs) =
    DoubleOrNothing <$> runMessage msg attrs

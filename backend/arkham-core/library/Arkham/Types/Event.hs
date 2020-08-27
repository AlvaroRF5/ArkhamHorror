{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event
  ( lookupEvent
  , Event(..)
  , eventLocation
  , ownerOfEvent
  )
where

import Arkham.Json
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Cards.Backstab
import Arkham.Types.Event.Cards.Barricade
import Arkham.Types.Event.Cards.BlindingLight
import Arkham.Types.Event.Cards.CunningDistraction
import Arkham.Types.Event.Cards.DarkMemory
import Arkham.Types.Event.Cards.Dodge
import Arkham.Types.Event.Cards.DrawnToTheFlame
import Arkham.Types.Event.Cards.DynamiteBlast
import Arkham.Types.Event.Cards.Elusive
import Arkham.Types.Event.Cards.EmergencyCache
import Arkham.Types.Event.Cards.Evidence
import Arkham.Types.Event.Cards.Lucky
import Arkham.Types.Event.Cards.MindOverMatter
import Arkham.Types.Event.Cards.OnTheLam
import Arkham.Types.Event.Cards.SneakAttack
import Arkham.Types.Event.Cards.WardOfProtection
import Arkham.Types.Event.Cards.WorkingAHunch
import Arkham.Types.Event.Runner
import Arkham.Types.EventId
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import ClassyPrelude
import Data.Coerce
import qualified Data.HashMap.Strict as HashMap
import Safe (fromJustNote)

lookupEvent :: CardCode -> (InvestigatorId -> EventId -> Event)
lookupEvent cardCode =
  fromJustNote ("Unknown event: " <> show cardCode)
    $ HashMap.lookup cardCode allEvents

allEvents :: HashMap CardCode (InvestigatorId -> EventId -> Event)
allEvents = HashMap.fromList
  [ ("01010", (OnTheLam' .) . onTheLam)
  , ("01013", (DarkMemory' .) . darkMemory)
  , ("01022", (Evidence' .) . evidence)
  , ("01023", (Dodge' .) . dodge)
  , ("01024", (DynamiteBlast' .) . dynamiteBlast)
  , ("01036", (MindOverMatter' .) . mindOverMatter)
  , ("01037", (WorkingAHunch' .) . workingAHunch)
  , ("01038", (Barricade' .) . barricade)
  , ("01050", (Elusive' .) . elusive)
  , ("01051", (Backstab' .) . backstab)
  , ("01052", (SneakAttack' .) . sneakAttack)
  , ("01064", (DrawnToTheFlame' .) . drawnToTheFlame)
  , ("01065", (WardOfProtection' .) . wardOfProtection)
  , ("01066", (BlindingLight' .) . blindingLight)
  , ("01078", (CunningDistraction' .) . cunningDistraction)
  , ("01080", (Lucky' .) . lucky)
  , ("01088", (EmergencyCache' .) . emergencyCache)
  ]

instance HasCardCode Event where
  getCardCode = eventCardCode . eventAttrs

data Event
  = OnTheLam' OnTheLam
  | DarkMemory' DarkMemory
  | Evidence' Evidence
  | Dodge' Dodge
  | DynamiteBlast' DynamiteBlast
  | MindOverMatter' MindOverMatter
  | WorkingAHunch' WorkingAHunch
  | Barricade' Barricade
  | Elusive' Elusive
  | Backstab' Backstab
  | SneakAttack' SneakAttack
  | DrawnToTheFlame' DrawnToTheFlame
  | WardOfProtection' WardOfProtection
  | BlindingLight' BlindingLight
  | CunningDistraction' CunningDistraction
  | Lucky' Lucky
  | EmergencyCache' EmergencyCache
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

eventAttrs :: Event -> Attrs
eventAttrs = \case
  OnTheLam' attrs -> coerce attrs
  DarkMemory' attrs -> coerce attrs
  Evidence' attrs -> coerce attrs
  Dodge' attrs -> coerce attrs
  DynamiteBlast' attrs -> coerce attrs
  MindOverMatter' attrs -> coerce attrs
  WorkingAHunch' attrs -> coerce attrs
  Barricade' attrs -> coerce attrs
  Elusive' attrs -> coerce attrs
  Backstab' attrs -> coerce attrs
  SneakAttack' attrs -> coerce attrs
  DrawnToTheFlame' attrs -> coerce attrs
  WardOfProtection' attrs -> coerce attrs
  BlindingLight' attrs -> coerce attrs
  CunningDistraction' attrs -> coerce attrs
  Lucky' attrs -> coerce attrs
  EmergencyCache' attrs -> coerce attrs

instance HasActions env investigator Event where
  getActions i window = \case
    OnTheLam' x -> getActions i window x
    DarkMemory' x -> getActions i window x
    Evidence' x -> getActions i window x
    Dodge' x -> getActions i window x
    DynamiteBlast' x -> getActions i window x
    MindOverMatter' x -> getActions i window x
    WorkingAHunch' x -> getActions i window x
    Barricade' x -> getActions i window x
    Elusive' x -> getActions i window x
    Backstab' x -> getActions i window x
    SneakAttack' x -> getActions i window x
    DrawnToTheFlame' x -> getActions i window x
    WardOfProtection' x -> getActions i window x
    BlindingLight' x -> getActions i window x
    CunningDistraction' x -> getActions i window x
    Lucky' x -> getActions i window x
    EmergencyCache' x -> getActions i window x

eventLocation :: Event -> Maybe LocationId
eventLocation = eventAttachedLocation . eventAttrs

ownerOfEvent :: Event -> InvestigatorId
ownerOfEvent = eventOwner . eventAttrs

instance (EventRunner env) => RunMessage env Event where
  runMessage msg = \case
    OnTheLam' x -> OnTheLam' <$> runMessage msg x
    DarkMemory' x -> DarkMemory' <$> runMessage msg x
    Evidence' x -> Evidence' <$> runMessage msg x
    Dodge' x -> Dodge' <$> runMessage msg x
    DynamiteBlast' x -> DynamiteBlast' <$> runMessage msg x
    MindOverMatter' x -> MindOverMatter' <$> runMessage msg x
    WorkingAHunch' x -> WorkingAHunch' <$> runMessage msg x
    Barricade' x -> Barricade' <$> runMessage msg x
    Elusive' x -> Elusive' <$> runMessage msg x
    Backstab' x -> Backstab' <$> runMessage msg x
    SneakAttack' x -> SneakAttack' <$> runMessage msg x
    DrawnToTheFlame' x -> DrawnToTheFlame' <$> runMessage msg x
    WardOfProtection' x -> WardOfProtection' <$> runMessage msg x
    BlindingLight' x -> BlindingLight' <$> runMessage msg x
    CunningDistraction' x -> CunningDistraction' <$> runMessage msg x
    Lucky' x -> Lucky' <$> runMessage msg x
    EmergencyCache' x -> EmergencyCache' <$> runMessage msg x

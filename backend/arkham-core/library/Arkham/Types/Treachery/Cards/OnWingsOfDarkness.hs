{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.OnWingsOfDarkness where

import Arkham.Json
import Arkham.Types.Classes
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner
import Arkham.Types.TreacheryId
import ClassyPrelude
import qualified Data.HashSet as HashSet
import Lens.Micro

newtype OnWingsOfDarkness = OnWingsOfDarkness Attrs
  deriving newtype (Show, ToJSON, FromJSON)

onWingsOfDarkness :: TreacheryId -> a -> OnWingsOfDarkness
onWingsOfDarkness uuid _ = OnWingsOfDarkness $ baseAttrs uuid "01173"

instance HasModifiersFor env OnWingsOfDarkness where
  getModifiersFor = noModifiersFor

instance HasActions env OnWingsOfDarkness where
  getActions i window (OnWingsOfDarkness attrs) = getActions i window attrs

instance (TreacheryRunner env) => RunMessage env OnWingsOfDarkness where
  runMessage msg (OnWingsOfDarkness attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      centralLocations <- HashSet.toList <$> asks (getSet [Central])
      unshiftMessage
        (RevelationSkillTest
          iid
          source
          SkillAgility
          4
          []
          ([ InvestigatorAssignDamage iid source 1 1
           , UnengageNonMatching iid [Nightgaunt]
           ]
          <> [ Ask iid $ ChooseOne
                 [ MoveTo iid lid | lid <- centralLocations ]
             ]
          )
          []
        )
      OnWingsOfDarkness <$> runMessage msg (attrs & resolved .~ True)
    _ -> OnWingsOfDarkness <$> runMessage msg attrs

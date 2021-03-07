module Arkham.Types.Location.Cards.ArtGallery
  ( artGallery
  , ArtGallery(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Types.Action as Action
import Arkham.Types.Classes
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationId
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Name
import Arkham.Types.Target
import Arkham.Types.Trait hiding (Cultist)

newtype ArtGallery = ArtGallery LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

artGallery :: LocationId -> ArtGallery
artGallery lid = ArtGallery
  $ base { locationVictory = Just 1, locationRevealedSymbol = Hourglass }
 where
  base = baseAttrs
    lid
    "02075"
    (Name "Art Gallery" Nothing)
    EncounterSet.TheHouseAlwaysWins
    2
    (PerPlayer 1)
    T
    [Diamond]
    [CloverClub]

instance HasModifiersFor env ArtGallery where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env ArtGallery where
  getActions iid window (ArtGallery attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env ArtGallery where
  runMessage msg l@(ArtGallery attrs@LocationAttrs {..}) = case msg of
    After (FailedSkillTest iid (Just Action.Investigate) _ (SkillTestInitiatorTarget _) _ _)
      -> l <$ unshiftMessage (SpendResources iid 2)
    _ -> ArtGallery <$> runMessage msg attrs

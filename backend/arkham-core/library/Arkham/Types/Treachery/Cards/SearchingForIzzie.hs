module Arkham.Types.Treachery.Cards.SearchingForIzzie
  ( SearchingForIzzie(..)
  , searchingForIzzie
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Query
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner
import Arkham.Types.Window

newtype SearchingForIzzie = SearchingForIzzie TreacheryAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

searchingForIzzie :: TreacheryCard SearchingForIzzie
searchingForIzzie = treachery SearchingForIzzie Cards.searchingForIzzie

instance HasModifiersFor env SearchingForIzzie where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env SearchingForIzzie where
  getActions iid NonFast (SearchingForIzzie attrs) = do
    investigatorLocationId <- getId @LocationId iid
    pure
      [ UseAbility
          iid
          (mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 2))
      | treacheryOnLocation investigatorLocationId attrs
      ]
  getActions _ _ _ = pure []

instance TreacheryRunner env => RunMessage env SearchingForIzzie where
  runMessage msg t@(SearchingForIzzie attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      farthestLocations <- map unFarthestLocationId <$> getSetList iid
      t <$ case farthestLocations of
        [lid] ->
          unshiftMessage (AttachTreachery treacheryId (LocationTarget lid))
        lids -> unshiftMessage
          (chooseOne
            iid
            [ AttachTreachery treacheryId (LocationTarget lid) | lid <- lids ]
          )
    UseCardAbility iid (TreacherySource tid) _ 1 _ | tid == treacheryId ->
      withTreacheryLocation attrs $ \attachedLocationId -> do
        shroud <- unShroud <$> getCount attachedLocationId
        t <$ unshiftMessage
          (BeginSkillTest
            iid
            (TreacherySource treacheryId)
            (InvestigatorTarget iid)
            (Just Action.Investigate)
            SkillIntellect
            shroud
          )
    PassedSkillTest _ _ source _ _ _ | isSource attrs source ->
      t <$ unshiftMessage (Discard $ toTarget attrs)
    EndOfGame ->
      let investigator = fromJustNote "missing investigator" treacheryOwner
      in t <$ unshiftMessage (SufferTrauma investigator 0 1)
    _ -> SearchingForIzzie <$> runMessage msg attrs

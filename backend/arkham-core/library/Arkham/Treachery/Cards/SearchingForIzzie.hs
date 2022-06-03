module Arkham.Treachery.Cards.SearchingForIzzie
  ( SearchingForIzzie(..)
  , searchingForIzzie
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Action qualified as Action
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Message hiding (InvestigatorEliminated)
import Arkham.SkillType
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Attrs
import Arkham.Treachery.Runner

newtype SearchingForIzzie = SearchingForIzzie TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

searchingForIzzie :: TreacheryCard SearchingForIzzie
searchingForIzzie = treachery SearchingForIzzie Cards.searchingForIzzie

instance HasAbilities SearchingForIzzie where
  getAbilities (SearchingForIzzie x) =
    restrictedAbility
        x
        1
        OnSameLocation
        (ActionAbility (Just Action.Investigate) $ ActionCost 2)
      : [ mkAbility x 2 $ ForcedAbility $ OrWindowMatcher
            [ GameEnds Timing.When
            , InvestigatorEliminated Timing.When (InvestigatorWithId iid)
            ]
        | iid <- maybeToList (treacheryOwner x)
        ]

instance TreacheryRunner env => RunMessage SearchingForIzzie where
  runMessage msg t@(SearchingForIzzie attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      targets <- selectListMap LocationTarget $ FarthestLocationFromYou Anywhere
      t <$ case targets of
        [] -> pure ()
        xs ->
          push
            (chooseOrRunOne
              iid
              [ AttachTreachery treacheryId target | target <- xs ]
            )
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      withTreacheryLocation attrs $ \locationId -> t <$ push
        (Investigate
          iid
          locationId
          source
          (Just $ toTarget attrs)
          SkillIntellect
          False
        )
    Successful (Action.Investigate, _) _ _ target _ | isTarget attrs target ->
      t <$ push (Discard target)
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      let investigator = fromJustNote "missing investigator" treacheryOwner
      in t <$ push (SufferTrauma investigator 0 1)
    _ -> SearchingForIzzie <$> runMessage msg attrs

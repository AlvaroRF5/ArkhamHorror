{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.Story.Runner (
  module Arkham.Story.Runner,
  module X,
) where

import Arkham.Prelude

import Arkham.Classes as X
import Arkham.Helpers.Message as X
import Arkham.Message as X hiding (story)
import Arkham.Story.Types as X
import Arkham.Target as X

import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Scenario
import Arkham.Placement
import Arkham.Scenario.Types (Field (..))

afterStoryResolution :: (HasQueue Message m) => StoryAttrs -> Message -> m ()
afterStoryResolution (toId -> storyId) = pushAfter isResolution
 where
  isResolution = \case
    ResolvedStory _ story' | story' == storyId -> True
    _ -> False

getAlreadyResolved :: (HasGame m) => StoryAttrs -> m Bool
getAlreadyResolved (toId -> storyId) = scenarioFieldMap ScenarioResolvedStories (elem storyId)

instance RunMessage Story where
  runMessage msg (Story a) = Story <$> runMessage msg a

instance RunMessage StoryAttrs where
  runMessage msg attrs = case msg of
    ResolvedStory _ story' | story' == toId attrs -> do
      when (storyPlacement attrs == Unplaced) $
        push $
          RemoveStory $
            toId attrs
      pure attrs
    ResolveStory iid DoNotResolveIt story' | story' == toId attrs -> do
      push $ chooseOne iid [targetLabel (toTarget attrs) []]
      pure attrs
    _ -> pure attrs

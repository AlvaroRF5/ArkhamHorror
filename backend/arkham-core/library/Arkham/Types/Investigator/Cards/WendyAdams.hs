module Arkham.Types.Investigator.Cards.WendyAdams
  ( WendyAdams(..)
  , wendyAdams
  ) where

import Arkham.Import

import Arkham.Types.Game.Helpers
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Stats
import Arkham.Types.Trait

newtype WendyAdams = WendyAdams Attrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

instance HasModifiersFor env WendyAdams where
  getModifiersFor source target (WendyAdams attrs) =
    getModifiersFor source target attrs

wendyAdams :: WendyAdams
wendyAdams = WendyAdams $ baseAttrs
  "01005"
  "Wendy Adams"
  Survivor
  Stats
    { health = 7
    , sanity = 7
    , willpower = 4
    , intellect = 3
    , combat = 1
    , agility = 4
    }
  [Drifter]

instance HasTokenValue env WendyAdams where
  getTokenValue (WendyAdams attrs) iid ElderSign | iid == investigatorId attrs =
    pure $ TokenValue ElderSign (PositiveModifier 0)
  getTokenValue (WendyAdams attrs) iid token = getTokenValue attrs iid token

ability :: Attrs -> Token -> Ability
ability attrs token = base
  { abilityLimit = PlayerLimit PerTestOrAbility 1
  , abilityMetadata = Just (TargetMetadata $ TokenFaceTarget token)
  }
 where
  base = mkAbility
    (toSource attrs)
    1
    (ReactionAbility $ HandDiscardCost 1 Nothing mempty mempty)

instance ActionRunner env => HasActions env WendyAdams where
  getActions iid (WhenRevealToken You token) (WendyAdams attrs@Attrs {..})
    | iid == investigatorId = pure
      [ActivateCardAbilityAction investigatorId $ ability attrs token]
  getActions i window (WendyAdams attrs) = getActions i window attrs

instance (InvestigatorRunner env) => RunMessage env WendyAdams where
  runMessage msg i@(WendyAdams attrs@Attrs {..}) = case msg of
    UseCardAbility _ (InvestigatorSource iid) (Just (TargetMetadata (TokenFaceTarget token))) 1 _
      | iid == investigatorId
      -> do
        cancelToken token
        i <$ unshiftMessages
          [ CancelNext DrawTokenMessage
          , CancelNext RevealTokenMessage
          , ReturnTokens [token]
          , UnfocusTokens
          , DrawAnotherToken iid
          ]
    When (DrawToken iid token) | iid == investigatorId -> i <$ unshiftMessages
      [ FocusTokens [token]
      , CheckWindow investigatorId [WhenDrawToken You token]
      , UnfocusTokens
      ]
    ResolveToken _drawnToken ElderSign iid | iid == investigatorId -> do
      maid <- getId @(Maybe AssetId) (CardCode "01014")
      i <$ when (isJust maid) (unshiftMessage PassSkillTest)
    _ -> WendyAdams <$> runMessage msg attrs

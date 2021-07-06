module Arkham.Types.Investigator.Cards.ZoeySamaras where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.ClassSymbol
import Arkham.Types.Cost
import Arkham.Types.Effect.Window
import Arkham.Types.EffectMetadata
import Arkham.Types.Game.Helpers
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Source
import Arkham.Types.Stats
import Arkham.Types.Target
import Arkham.Types.Token
import Arkham.Types.Trait
import Arkham.Types.Window

newtype ZoeySamaras = ZoeySamaras InvestigatorAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

instance HasModifiersFor env ZoeySamaras where
  getModifiersFor source target (ZoeySamaras attrs) =
    getModifiersFor source target attrs

zoeySamaras :: ZoeySamaras
zoeySamaras = ZoeySamaras $ baseAttrs
  "02001"
  "Zoey Samaras"
  Guardian
  Stats
    { health = 9
    , sanity = 6
    , willpower = 4
    , intellect = 2
    , combat = 4
    , agility = 2
    }
  [Believer, Hunter]

instance InvestigatorRunner env => HasActions env ZoeySamaras where
  getActions iid (AfterEnemyEngageInvestigator You _) (ZoeySamaras InvestigatorAttrs {..})
    | iid == investigatorId
    = do
      let
        ability =
          mkAbility (InvestigatorSource investigatorId) 1 (ReactionAbility Free)
      modifiers' <-
        map modifierType
          <$> getModifiersFor
                (InvestigatorSource investigatorId)
                (InvestigatorTarget investigatorId)
                ()
      pure
        [ UseAbility investigatorId ability
        | CannotGainResources `notElem` modifiers'
        ]

  getActions i window (ZoeySamaras attrs) = getActions i window attrs

instance HasTokenValue env ZoeySamaras where
  getTokenValue (ZoeySamaras attrs) iid ElderSign
    | iid == investigatorId attrs = pure
    $ TokenValue ElderSign (PositiveModifier 1)
  getTokenValue (ZoeySamaras attrs) iid token = getTokenValue attrs iid token

instance InvestigatorRunner env => RunMessage env ZoeySamaras where
  runMessage msg i@(ZoeySamaras attrs@InvestigatorAttrs {..}) = case msg of
    UseCardAbility _ (InvestigatorSource iid) _ 1 _ | iid == investigatorId ->
      i <$ push (TakeResources investigatorId 1 False)
    ResolveToken _drawnToken ElderSign iid | iid == investigatorId -> i <$ push
      (CreateWindowModifierEffect
        EffectSkillTestWindow
        (EffectModifiers $ toModifiers attrs [DamageDealt 1])
        (InvestigatorSource investigatorId)
        (InvestigatorTarget investigatorId)
      )
    _ -> ZoeySamaras <$> runMessage msg attrs

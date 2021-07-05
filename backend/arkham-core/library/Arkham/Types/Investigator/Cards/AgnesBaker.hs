module Arkham.Types.Investigator.Cards.AgnesBaker
  ( AgnesBaker(..)
  , agnesBaker
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.EnemyId
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Message
import Arkham.Types.Stats
import Arkham.Types.Token
import Arkham.Types.Trait
import Arkham.Types.Window

newtype AgnesBaker = AgnesBaker InvestigatorAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

instance HasModifiersFor env AgnesBaker where
  getModifiersFor source target (AgnesBaker attrs) =
    getModifiersFor source target attrs

agnesBaker :: AgnesBaker
agnesBaker = AgnesBaker
  $ baseAttrs "01004" "Agnes Baker" Mystic stats [Sorcerer]
 where
  stats = Stats
    { health = 6
    , sanity = 8
    , willpower = 5
    , intellect = 2
    , combat = 2
    , agility = 3
    }

ability :: InvestigatorAttrs -> Ability
ability attrs = base { abilityLimit = PlayerLimit PerPhase 1 }
  where base = mkAbility (toSource attrs) 1 (ReactionAbility Free)

instance InvestigatorRunner env => HasActions env AgnesBaker where
  getActions iid (WhenDealtHorror _ target) (AgnesBaker attrs)
    | isTarget attrs target = do
      enemyIds <- getSet @EnemyId $ investigatorLocation attrs
      pure [ UseAbility iid (ability attrs) | not (null enemyIds) ]
  getActions i window (AgnesBaker attrs) = getActions i window attrs

instance HasTokenValue env AgnesBaker where
  getTokenValue (AgnesBaker attrs) iid ElderSign | iid == toId attrs = do
    let tokenValue' = PositiveModifier $ investigatorSanityDamage attrs
    pure $ TokenValue ElderSign tokenValue'
  getTokenValue (AgnesBaker attrs) iid token = getTokenValue attrs iid token

instance (InvestigatorRunner env) => RunMessage env AgnesBaker where
  runMessage msg i@(AgnesBaker attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      enemyIds <- getSetList $ investigatorLocation attrs
      i <$ unshiftMessage
        (chooseOne
          (toId attrs)
          [ EnemyDamage eid (toId attrs) source 1 | eid <- enemyIds ]
        )
    _ -> AgnesBaker <$> runMessage msg attrs

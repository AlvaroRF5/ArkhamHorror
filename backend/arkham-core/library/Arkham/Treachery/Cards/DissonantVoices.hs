module Arkham.Treachery.Cards.DissonantVoices where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Card
import Arkham.Classes
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Helpers
import Arkham.Treachery.Runner

newtype DissonantVoices = DissonantVoices TreacheryAttrs
  deriving anyclass (IsTreachery)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

dissonantVoices :: TreacheryCard DissonantVoices
dissonantVoices = treachery DissonantVoices Cards.dissonantVoices

instance HasModifiersFor DissonantVoices where
  getModifiersFor (InvestigatorTarget iid) (DissonantVoices attrs) =
    pure
      $ toModifiers attrs
      $ [ CannotPlay (CardWithOneOf $ map CardWithType [AssetType, EventType])
        | treacheryOnInvestigator iid attrs
        ]
  getModifiersFor _ _ = pure []

instance HasAbilities DissonantVoices where
  getAbilities (DissonantVoices a) =
    [ restrictedAbility a 1 (InThreatAreaOf You)
        $ ForcedAbility
        $ RoundEnds Timing.When
    ]

instance RunMessage DissonantVoices where
  runMessage msg t@(DissonantVoices attrs) = case msg of
    Revelation iid (isSource attrs -> True) -> do
      push $ AttachTreachery (toId t) (InvestigatorTarget iid)
      pure t
    UseCardAbility _ (isSource attrs -> True) 1 _ _ -> do
      push $ Discard (toAbilitySource attrs 1) (toTarget attrs)
      pure t
    _ -> DissonantVoices <$> runMessage msg attrs

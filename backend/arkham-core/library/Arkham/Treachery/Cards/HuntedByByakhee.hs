module Arkham.Treachery.Cards.HuntedByByakhee
  ( huntedByByakhee
  , HuntedByByakhee(..)
  ) where

import Arkham.Prelude

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Card
import Arkham.Classes
import Arkham.Message
import Arkham.SkillType
import Arkham.Target
import Arkham.Trait
import Arkham.Treachery.Attrs

newtype HuntedByByakhee = HuntedByByakhee TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

huntedByByakhee :: TreacheryCard HuntedByByakhee
huntedByByakhee = treachery HuntedByByakhee Cards.huntedByByakhee

instance RunMessage HuntedByByakhee where
  runMessage msg t@(HuntedByByakhee attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (RevelationSkillTest iid source SkillAgility 6)
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ n
      | isSource attrs source -> do
        t <$ pushAll
          [ DiscardTopOfEncounterDeck iid n (Just $ toTarget attrs)
          , ShuffleIntoEncounterDeck []
          ]
    DiscardedTopOfEncounterDeck iid cards target | isTarget attrs target -> do
      let
        isByakhee = member Byakhee . cdCardTraits . toCardDef
        isOmen = member Omen . cdCardTraits . toCardDef
        byakhee = filter isByakhee cards
        omens = filter isOmen cards
        byakheeMsgs = if null byakhee
          then []
          else
            [ FocusCards $ map EncounterCard cards
            , chooseOne
              iid
              [ TargetLabel
                  (CardIdTarget $ toCardId enemy)
                  [ RemoveFromEncounterDiscard enemy
                  , InvestigatorDrewEncounterCard iid enemy
                  ]
              | enemy <- byakhee
              ]
            , UnfocusCards
            ]
      pushAll
        $ byakheeMsgs
        <> [ InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 1
           | not (null omens)
           ]
      pure t
    _ -> HuntedByByakhee <$> runMessage msg attrs

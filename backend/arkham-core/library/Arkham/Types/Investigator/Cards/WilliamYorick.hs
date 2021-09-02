module Arkham.Types.Investigator.Cards.WilliamYorick where

import Arkham.Prelude

import Arkham.Types.Card
import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.Id
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Message hiding (EnemyDefeated)
import Arkham.Types.Source
import Arkham.Types.Stats
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Token
import Arkham.Types.Trait
import Arkham.Types.Window

newtype WilliamYorick = WilliamYorick InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor env)
  deriving newtype (Show, ToJSON, FromJSON, Entity)

williamYorick :: WilliamYorick
williamYorick = WilliamYorick $ baseAttrs
  "03005"
  "William Yorick"
  Survivor
  Stats
    { health = 8
    , sanity = 6
    , willpower = 3
    , intellect = 2
    , combat = 4
    , agility = 3
    }
  [Warden]

instance HasTokenValue env WilliamYorick where
  getTokenValue (WilliamYorick attrs) iid ElderSign
    | iid == investigatorId attrs = pure
    $ TokenValue ElderSign (PositiveModifier 2)
  getTokenValue _ _ token = pure $ TokenValue token mempty

instance HasAbilities WilliamYorick where
  getAbilities = error "not working"

instance InvestigatorRunner env => RunMessage env WilliamYorick where
  runMessage msg i@(WilliamYorick attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      let
        targets =
          filter ((== AssetType) . toCardType) (investigatorDiscard attrs)
        playCardMsgs c =
          [ AddToHand iid c
          , if isDynamic c
            then InitiatePlayDynamicCard iid (toCardId c) 0 Nothing False
            else InitiatePlayCard iid (toCardId c) Nothing False
          ]
      playableTargets <- filterM
        (getIsPlayable
            iid
            source
            [Window Timing.When NonFast, Window Timing.When (DuringTurn iid)]
        . PlayerCard
        )
        targets
      i <$ push
        (chooseOne iid
        $ [ TargetLabel
              (CardIdTarget $ toCardId card)
              (playCardMsgs $ PlayerCard card)
          | card <- playableTargets
          ]
        )
    ResolveToken _ ElderSign iid | iid == toId attrs -> do
      i <$ push
        (CreateEffect
          (unInvestigatorId $ toId attrs)
          Nothing
          (TokenEffectSource ElderSign)
          (InvestigatorTarget iid)
        )
    _ -> WilliamYorick <$> runMessage msg attrs

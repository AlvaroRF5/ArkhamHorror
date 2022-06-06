module Arkham.Asset.Cards.Fieldwork
  ( fieldwork
  , Fieldwork(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Card.CardCode
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Target
import Arkham.Timing qualified as Timing

newtype Fieldwork = Fieldwork AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fieldwork :: AssetCard Fieldwork
fieldwork = asset Fieldwork Cards.fieldwork

instance HasAbilities Fieldwork where
  getAbilities (Fieldwork attrs) =
    [ restrictedAbility
        attrs
        1
        OwnsThis
        (ReactionAbility
            (Enters Timing.After You
            $ LocationWithClues (GreaterThan $ Static 0)
            )
        $ ExhaustCost
        $ toTarget attrs
        )
    ]

instance RunMessage Fieldwork where
  runMessage msg a@(Fieldwork attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a
        <$ push
             (CreateEffect (toCardCode attrs) Nothing source
             $ InvestigatorTarget iid
             )
    _ -> Fieldwork <$> runMessage msg attrs

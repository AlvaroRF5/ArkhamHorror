module Arkham.Effect.Effects.GildedVolto
  ( GildedVolto(..)
  , gildedVolto
  ) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.Message
import Arkham.Source
import Arkham.Target

newtype GildedVolto = GildedVolto EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

gildedVolto :: EffectArgs -> GildedVolto
gildedVolto = GildedVolto . uncurry4 (baseAttrs "82026")

instance HasModifiersFor GildedVolto where
  getModifiersFor _ target (GildedVolto a) | target == effectTarget a =
    pure [toModifier a $ CanBecomeFast $ CardWithType AssetType]
  getModifiersFor (InvestigatorSource iid) (CardTarget card) (GildedVolto a)
    | InvestigatorTarget iid == effectTarget a = pure
      [ toModifier a BecomesFast | cardMatch card (CardWithType AssetType) ]
  getModifiersFor _ _ _ = pure []

instance RunMessage GildedVolto where
  runMessage msg e@(GildedVolto attrs) = case msg of
    PlayedCard iid card
      | InvestigatorTarget iid == effectTarget attrs && cardMatch
        card
        (CardWithType AssetType)
      -> e <$ push (DisableEffect $ toId attrs)
    EndTurn _ ->
      e <$ push (DisableEffect $ toId attrs)
    _ -> GildedVolto <$> runMessage msg attrs

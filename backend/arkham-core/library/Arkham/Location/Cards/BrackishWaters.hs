module Arkham.Location.Cards.BrackishWaters
  ( BrackishWaters(..)
  , brackishWaters
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Assets
import Arkham.Location.Cards qualified as Cards
import Arkham.Card
import Arkham.Card.PlayerCard
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.GameValue
import Arkham.Location.Attrs
import Arkham.Location.Helpers
import Arkham.Matcher
import Arkham.Message
import Arkham.Modifier
import Arkham.SkillType
import Arkham.Target

newtype BrackishWaters = BrackishWaters LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

brackishWaters :: LocationCard BrackishWaters
brackishWaters = location
  BrackishWaters
  Cards.brackishWaters
  1
  (Static 0)
  Triangle
  [Squiggle, Square, Diamond, Hourglass]

instance HasModifiersFor env BrackishWaters where
  getModifiersFor _ (InvestigatorTarget iid) (BrackishWaters attrs) =
    pure $ toModifiers
      attrs
      [ CannotPlay [(AssetType, mempty)]
      | iid `elem` locationInvestigators attrs
      ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities BrackishWaters where
  getAbilities (BrackishWaters attrs) = withBaseAbilities
    attrs
    [ restrictedAbility
        attrs
        1
        (Here <> Negate (AssetExists $ assetIs Assets.fishingNet))
      $ ActionAbility Nothing
      $ Costs
          [ ActionCost 1
          , DiscardFromCost
            2
            (FromHandOf You <> FromPlayAreaOf You)
            (CardWithType AssetType)
          ]
    | locationRevealed attrs
    ]

instance LocationRunner env => RunMessage env BrackishWaters where
  runMessage msg l@(BrackishWaters attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      l <$ push
        (BeginSkillTest iid source (toTarget attrs) Nothing SkillAgility 3)
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        fishingNet <- PlayerCard <$> genPlayerCard Assets.fishingNet
        l <$ push (TakeControlOfSetAsideAsset iid fishingNet)
    _ -> BrackishWaters <$> runMessage msg attrs

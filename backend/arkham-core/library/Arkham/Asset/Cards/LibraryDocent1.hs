module Arkham.Asset.Cards.LibraryDocent1
  ( libraryDocent1
  , libraryDocent1Effect
  , LibraryDocent1(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Card
import Arkham.Cost
import Arkham.Criteria hiding ( DuringTurn )
import Arkham.Effect.Runner ()
import Arkham.Effect.Types
import Arkham.Investigator.Types ( Field (..) )
import Arkham.Matcher hiding ( DuringTurn, FastPlayerWindow )
import Arkham.Name
import Arkham.Projection
import Arkham.Timing qualified as Timing
import Arkham.Trait ( Trait (Tome) )
import Arkham.Window
import Control.Newtype ( ala )
import Data.Monoid ( First (..) )

newtype LibraryDocent1 = LibraryDocent1 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

libraryDocent1 :: AssetCard LibraryDocent1
libraryDocent1 = ally LibraryDocent1 Cards.libraryDocent1 (1, 2)

instance HasAbilities LibraryDocent1 where
  getAbilities (LibraryDocent1 a) =
    [ restrictedAbility
          a
          1
          (ControlsThis <> PlayableCardExistsWithCostReduction 2
            (HandCardWithDifferentTitleFromAtLeastOneAsset
              You
              (AssetWithTrait Tome)
              (CardWithTrait Tome <> CardWithType AssetType)
            )
          )
        $ ReactionAbility (AssetEntersPlay Timing.When $ AssetWithId $ toId a)
        $ ReturnMatchingAssetToHandCost
        $ AssetWithDifferentTitleFromAtLeastOneCardInHand
            You
            (CardWithTrait Tome <> CardWithType AssetType)
            (AssetWithTrait Tome)
    ]

getAssetPayment :: Payment -> Maybe Card
getAssetPayment (ReturnToHandPayment c) = Just c
getAssetPayment (Payments ps) = ala First foldMap $ map getAssetPayment ps
getAssetPayment _ = Nothing

instance RunMessage LibraryDocent1 where
  runMessage msg a@(LibraryDocent1 attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 windows' (getAssetPayment -> Just assetPayment)
      -> do
        handCards <- field InvestigatorHand iid
        let
          windows'' =
            nub
              $ windows'
              <> [ Window Timing.When (DuringTurn iid)
                 , Window Timing.When FastPlayerWindow
                 ]
          targetCards = filter
            (and . sequence
              [ (`cardMatch` (CardWithType AssetType <> CardWithTrait Tome))
              , (/= (toName assetPayment)) . toName
              ]
            )
            handCards
        push $ chooseOne
          iid
          [ TargetLabel
              (CardIdTarget $ toCardId tome)
              [ createCardEffect
                Cards.libraryDocent1
                Nothing
                (toSource attrs)
                (CardIdTarget $ toCardId tome)
              , PayCardCost iid tome windows''
              ]
          | tome <- targetCards
          ]
        pure a
    _ -> LibraryDocent1 <$> runMessage msg attrs

newtype LibraryDocent1Effect = LibraryDocent1Effect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

libraryDocent1Effect :: EffectArgs -> LibraryDocent1Effect
libraryDocent1Effect = cardEffect LibraryDocent1Effect Cards.libraryDocent1

instance HasModifiersFor LibraryDocent1Effect where
  getModifiersFor target@(CardIdTarget cid) (LibraryDocent1Effect attrs)
    | effectTarget attrs == target = pure
    $ toModifiers attrs [ReduceCostOf (CardWithId cid) 2]
  getModifiersFor _ _ = pure []

instance RunMessage LibraryDocent1Effect where
  runMessage msg e@(LibraryDocent1Effect attrs) = case msg of
    ResolvedCard _ card | CardIdTarget (toCardId card) == effectTarget attrs ->
      e <$ push (DisableEffect $ toId attrs)
    _ -> LibraryDocent1Effect <$> runMessage msg attrs

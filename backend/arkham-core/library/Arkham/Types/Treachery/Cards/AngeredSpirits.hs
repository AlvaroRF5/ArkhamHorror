module Arkham.Types.Treachery.Cards.AngeredSpirits
  ( angeredSpirits
  , AngeredSpirits(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Uses
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner
import Arkham.Types.Window

newtype AngeredSpirits = AngeredSpirits TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

angeredSpirits :: TreacheryCard AngeredSpirits
angeredSpirits =
  treacheryWith AngeredSpirits Cards.angeredSpirits (resourcesL ?~ 0)

instance HasModifiersFor env AngeredSpirits

instance HasActions env AngeredSpirits where
  getActions i FastPlayerWindow (AngeredSpirits attrs) = do
    pure
      [ UseAbility
          i
          (mkAbility
            attrs
            1
            (FastAbility
            $ ExhaustAssetCost
            $ AssetWithTrait Spell
            <> AssetOwnedBy You
            )
          )
      ]
  getActions i window (AngeredSpirits attrs) = getActions i window attrs

angeredSpiritsCharges :: TreacheryAttrs -> Int
angeredSpiritsCharges TreacheryAttrs { treacheryResources } =
  fromJustNote "must be set" treacheryResources

instance TreacheryRunner env => RunMessage env AngeredSpirits where
  runMessage msg t@(AngeredSpirits attrs) = case msg of
    Revelation iid source | isSource attrs source -> t <$ pushAll
      [ RemoveCardFromHand iid (toCardId attrs)
      , AttachTreachery (toId attrs) (InvestigatorTarget iid)
      ]
    InvestigatorEliminated iid | treacheryOnInvestigator iid attrs ->
      runMessage EndOfGame t >>= \case
        AngeredSpirits attrs' -> AngeredSpirits <$> runMessage msg attrs'
    EndOfGame | angeredSpiritsCharges attrs < 4 ->
      withTreacheryInvestigator attrs
        $ \tormented -> t <$ push (SufferTrauma tormented 1 0)
    UseCardAbility _ source _ 1 (ExhaustPayment [target])
      | isSource attrs source
      -> t <$ pushAll
        [SpendUses target Charge 1, PlaceResources (toTarget attrs) 1]
    _ -> AngeredSpirits <$> runMessage msg attrs

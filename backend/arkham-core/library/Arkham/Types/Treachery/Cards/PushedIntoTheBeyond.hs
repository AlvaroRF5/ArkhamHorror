module Arkham.Types.Treachery.Cards.PushedIntoTheBeyond
  ( PushedIntoTheBeyond(..)
  , pushedIntoTheBeyond
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.EffectMetadata
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype PushedIntoTheBeyond = PushedIntoTheBeyond TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

pushedIntoTheBeyond :: TreacheryCard PushedIntoTheBeyond
pushedIntoTheBeyond = treachery PushedIntoTheBeyond Cards.pushedIntoTheBeyond

instance HasModifiersFor env PushedIntoTheBeyond

instance HasActions env PushedIntoTheBeyond where
  getActions i window (PushedIntoTheBeyond attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env PushedIntoTheBeyond where
  runMessage msg t@(PushedIntoTheBeyond attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      validAssets <- selectList (AssetOwnedBy iid <> AssetNonStory)
      targets <- traverse (traverseToSnd getId) validAssets
      t <$ if notNull targets
        then push
          (chooseOne
            iid
            [ TargetLabel
                (AssetTarget aid)
                [ ShuffleIntoDeck iid (AssetTarget aid)
                , CreateEffect
                  (CardCode "02100")
                  (Just (EffectCardCode cardCode))
                  (toSource attrs)
                  (InvestigatorTarget iid)
                , Discard (toTarget attrs)
                ]
            | (aid, cardCode) <- targets
            ]
          )
        else push (Discard $ toTarget attrs)
    _ -> PushedIntoTheBeyond <$> runMessage msg attrs

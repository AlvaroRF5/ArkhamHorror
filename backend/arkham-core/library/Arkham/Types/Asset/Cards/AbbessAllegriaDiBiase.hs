module Arkham.Types.Asset.Cards.AbbessAllegriaDiBiase
  ( abbessAllegriaDiBiase
  , AbbessAllegriaDiBiase(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Id
import Arkham.Types.Matcher
import Arkham.Types.Message
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Window

newtype AbbessAllegriaDiBiase = AbbessAllegriaDiBiase AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

abbessAllegriaDiBiase :: AssetCard AbbessAllegriaDiBiase
abbessAllegriaDiBiase =
  ally AbbessAllegriaDiBiase Cards.abbessAllegriaDiBiase (2, 2)

instance HasAbilities env AbbessAllegriaDiBiase where
  getAbilities _ _ (AbbessAllegriaDiBiase attrs) =
    pure $ case assetLocation attrs of
      Just abbessLocation ->
        [ restrictedAbility
            attrs
            1
            (AnyCriteria
              [ LocationExists
                (LocationWithId abbessLocation <> AccessibleLocation)
              , LocationExists
                (AccessibleFrom (LocationWithId abbessLocation)
                <> AccessibleLocation
                )
              ]
            )
            (FastAbility $ ExhaustCost (toTarget attrs))
        ]
      Nothing -> []

getAssetLocation
  :: (MonadReader env m, HasId LocationId env InvestigatorId)
  => AssetAttrs
  -> m LocationId
getAssetLocation AssetAttrs {..} = case assetLocation of
  Just location -> pure location
  Nothing -> case assetInvestigator of
    Just iid -> getId iid
    Nothing -> error "Invalid location for Abbess"

instance
  ( HasSet ConnectedLocationId env LocationId
  , HasId LocationId env InvestigatorId
  , HasSet InvestigatorId env ()
  , HasQueue env
  , HasModifiersFor env ()
  )
  => RunMessage env AbbessAllegriaDiBiase where
  runMessage msg a@(AbbessAllegriaDiBiase attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      investigatorLocationId <- getId @LocationId iid
      abbessLocationId <- getAssetLocation attrs
      a <$ if investigatorLocationId == abbessLocationId
        then do
          connectedLocationIds <- map unConnectedLocationId
            <$> getSetList abbessLocationId
          push
            (chooseOne
              iid
              [ MoveAction iid connectedLocationId Free False
              | connectedLocationId <- connectedLocationIds
              ]
            )
        else push (MoveAction iid abbessLocationId Free False)
    _ -> AbbessAllegriaDiBiase <$> runMessage msg attrs

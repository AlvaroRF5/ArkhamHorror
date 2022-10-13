{-# LANGUAGE QuantifiedConstraints #-}
module Arkham.Field.Matchers where

import Arkham.Prelude
import Arkham.Field
import Arkham.Asset.Types
import Data.Typeable

-- This module is currently abandoned. It causes a recompilation of Matcher and
-- due to that taking time it is preferable not to, however, the code is being
-- kept around if perhaps haskell 9.4 fixes the recompilation hits.

newtype AssetFieldEq = AssetFieldEq (FieldEq Asset)
  deriving newtype (ToJSON, FromJSON, Show, Eq, Hashable)

data FieldEq a where
  FieldEq :: forall a typ fld. (fld ~ Field a typ, Show fld, Hashable typ, Hashable fld, Typeable a, Typeable typ, Show typ, Eq typ, ToJSON typ, ToJSON fld) => fld -> typ -> FieldEq a

deriving stock instance Show (FieldEq a)

instance Eq (FieldEq a) where
  FieldEq (f1 :: f1) (t1 :: t1) == FieldEq (f2 :: f2) (t2 :: t2) =
    case eqT @f1 @f2 of
      Just Refl ->
        case eqT @t1 @t2 of
          Just Refl -> f1 == f2 && t1 == t2
          Nothing -> False
      Nothing -> False

instance ToJSON (FieldEq a) where
  toJSON (FieldEq (fld :: Field a typ) v) = object ["field" .= fld, "value" .= v, "entity" .= show (typeRep $ Proxy @a)]

instance (forall typ. Hashable (Field a typ), forall typ. ToJSON (Field a typ), Typeable a) => FromJSON (FieldEq a) where
  parseJSON = withObject "FieldEq a" $ \o -> do
    entity :: Text <- o .: "entity"
    case entity of
      "Asset" -> do
        case eqT @a @Asset of
          Nothing -> error "entity mismatch"
          Just Refl -> do
            sfld :: SomeField Asset <- o .: "field"
            case sfld of
              SomeField (fld :: Field Asset typ) ->
                withFieldDict @FromJSON fld $
                withFieldDict @ToJSON fld $
                withFieldDict @Hashable fld $
                withFieldDict @Typeable fld $
                withFieldDict @Show fld $ do
                  v :: typ <- o .: "value"
                  pure $ FieldEq fld v
      _ -> error "unhandled entity"

instance Hashable (FieldEq a) where
  hashWithSalt s (FieldEq fld v) = s + (hash fld) + (hash v)

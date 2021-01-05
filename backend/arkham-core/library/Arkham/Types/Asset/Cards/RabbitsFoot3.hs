module Arkham.Types.Asset.Cards.RabbitsFoot3
  ( RabbitsFoot3(..)
  , rabbitsFoot3
  )
where

import Arkham.Import

import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Runner

newtype RabbitsFoot3 = RabbitsFoot3 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

rabbitsFoot3 :: AssetId -> RabbitsFoot3
rabbitsFoot3 uuid =
  RabbitsFoot3 $ (baseAttrs uuid "50010") { assetSlots = [AccessorySlot] }

instance HasModifiersFor env RabbitsFoot3 where
  getModifiersFor = noModifiersFor

ability :: Attrs -> Int -> Ability
ability attrs n =
  (mkAbility (toSource attrs) 1 (ReactionAbility $ ExhaustCost (toTarget attrs))
    )
    { abilityMetadata = Just (IntMetadata n)
    }

instance HasActions env RabbitsFoot3 where
  getActions iid (AfterFailSkillTest You n) (RabbitsFoot3 a) | ownedBy a iid =
    pure [ActivateCardAbilityAction iid (ability a n)]
  getActions i window (RabbitsFoot3 x) = getActions i window x

instance AssetRunner env => RunMessage env RabbitsFoot3 where
  runMessage msg a@(RabbitsFoot3 attrs) = case msg of
    UseCardAbility iid source (Just (IntMetadata x)) 1
      | isSource attrs source -> a <$ unshiftMessage
        (SearchTopOfDeck iid (InvestigatorTarget iid) x mempty ShuffleBackIn)
    _ -> RabbitsFoot3 <$> runMessage msg attrs

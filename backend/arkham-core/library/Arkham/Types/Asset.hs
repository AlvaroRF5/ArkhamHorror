{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Asset
  ( lookupAsset
  , allAssets
  , isHealthDamageable
  , isSanityDamageable
  , slotsOf
  , Asset
  )
where

import Arkham.Json
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Cards
import Arkham.Types.Asset.Runner
import Arkham.Types.Asset.Uses
import Arkham.Types.AssetId
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Query
import Arkham.Types.Slot
import ClassyPrelude
import Data.Coerce
import Safe (fromJustNote)

data Asset
  = Rolands38Special' Rolands38Special
  | DaisysToteBag' DaisysToteBag
  | TheNecronomicon' TheNecronomicon
  | HeirloomOfHyperborea' HeirloomOfHyperborea
  | WendysAmulet' WendysAmulet
  | FortyFiveAutomatic' FortyFiveAutomatic
  | PhysicalTraining' PhysicalTraining
  | BeatCop' BeatCop
  | FirstAid' FirstAid
  | Machete' Machete
  | GuardDog' GuardDog
  | PoliceBadge2' PoliceBadge2
  | BeatCop2' BeatCop2
  | Shotgun4' Shotgun4
  | MagnifyingGlass' MagnifyingGlass
  | OldBookOfLore' OldBookOfLore
  | ResearchLibrarian' ResearchLibrarian
  | DrMilanChristopher' DrMilanChristopher
  | Hyperawareness' Hyperawareness
  | MedicalTexts' MedicalTexts
  | MagnifyingGlass1' MagnifyingGlass1
  | DiscOfItzamna2' DiscOfItzamna2
  | Encyclopedia2' Encyclopedia2
  | Switchblade' Switchblade
  | Burglary' Burglary
  | Pickpocketing' Pickpocketing
  | FortyOneDerringer' FortyOneDerringer
  | LeoDeLuca' LeoDeLuca
  | HardKnocks' HardKnocks
  | LeoDeLuca1' LeoDeLuca1
  | CatBurgler1' CatBurgler1
  | ForbiddenKnowledge' ForbiddenKnowledge
  | HolyRosary' HolyRosary
  | Shrivelling' Shrivelling
  | Scrying' Scrying
  | ArcaneStudies' ArcaneStudies
  | ArcaneInitiate' ArcaneInitiate
  | BookOfShadows3' BookOfShadows3
  | GrotesqueStatue4' GrotesqueStatue4
  | LeatherCoat' LeatherCoat
  | Scavenging' Scavenging
  | BaseballBat' BaseballBat
  | RabbitsFoot' RabbitsFoot
  | StrayCat' StrayCat
  | DigDeep' DigDeep
  | Knife' Knife
  | Flashlight' Flashlight
  | LitaChantler' LitaChantler
  | ZoeysCross' ZoeysCross
  | JennysTwin45s' JennysTwin45s
  | JimsTrumpet' JimsTrumpet
  | Duke' Duke
  | Bandolier' Bandolier
  | PhysicalTraining2' PhysicalTraining2
  | Hyperawareness2' Hyperawareness2
  | HardKnocks2' HardKnocks2
  | ArcaneStudies2' ArcaneStudies2
  | DigDeep2' DigDeep2
  | RabbitsFoot3' RabbitsFoot3
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

deriving anyclass instance (ActionRunner env investigator) => HasActions env investigator Asset
deriving anyclass instance (AssetRunner env) => RunMessage env Asset

instance HasCardCode Asset where
  getCardCode = assetCardCode . assetAttrs

instance HasTraits Asset where
  getTraits = assetTraits . assetAttrs

instance HasId AssetId () Asset where
  getId _ = assetId . assetAttrs

instance HasId (Maybe OwnerId) () Asset where
  getId _ = (OwnerId <$>) . assetInvestigator . assetAttrs

instance HasId (Maybe LocationId) () Asset where
  getId _ = assetLocation . assetAttrs

instance HasCount DoomCount () Asset where
  getCount _ = DoomCount . assetDoom . assetAttrs

instance HasCount UsesCount () Asset where
  getCount _ asset = case uses' of
    NoUses -> UsesCount 0
    Uses _ n -> UsesCount n
    where uses' = assetUses (assetAttrs asset)

lookupAsset :: CardCode -> (AssetId -> Asset)
lookupAsset = fromJustNote "Unkown asset" . flip lookup allAssets

allAssets :: HashMap CardCode (AssetId -> Asset)
allAssets = mapFromList
  [ ("01006", Rolands38Special' . rolands38Special)
  , ("01008", DaisysToteBag' . daisysToteBag)
  , ("01009", TheNecronomicon' . theNecronomicon)
  , ("01012", HeirloomOfHyperborea' . heirloomOfHyperborea)
  , ("01014", WendysAmulet' . wendysAmulet)
  , ("01016", FortyFiveAutomatic' . fortyFiveAutomatic)
  , ("01017", PhysicalTraining' . physicalTraining)
  , ("01018", BeatCop' . beatCop)
  , ("01019", FirstAid' . firstAid)
  , ("01020", Machete' . machete)
  , ("01021", GuardDog' . guardDog)
  , ("01027", PoliceBadge2' . policeBadge2)
  , ("01028", BeatCop2' . beatCop2)
  , ("01029", Shotgun4' . shotgun4)
  , ("01030", MagnifyingGlass' . magnifyingGlass)
  , ("01031", OldBookOfLore' . oldBookOfLore)
  , ("01032", ResearchLibrarian' . researchLibrarian)
  , ("01033", DrMilanChristopher' . drMilanChristopher)
  , ("01034", Hyperawareness' . hyperawareness)
  , ("01035", MedicalTexts' . medicalTexts)
  , ("01040", MagnifyingGlass1' . magnifyingGlass1)
  , ("01041", DiscOfItzamna2' . discOfItzamna2)
  , ("01042", Encyclopedia2' . encyclopedia2)
  , ("01044", Switchblade' . switchblade)
  , ("01045", Burglary' . burglary)
  , ("01046", Pickpocketing' . pickpoketing)
  , ("01047", FortyOneDerringer' . fortyOneDerringer)
  , ("01048", LeoDeLuca' . leoDeLuca)
  , ("01049", HardKnocks' . hardKnocks)
  , ("01054", LeoDeLuca1' . leoDeLuca1)
  , ("01055", CatBurgler1' . catBurgler1)
  , ("01058", ForbiddenKnowledge' . forbiddenKnowledge)
  , ("01059", HolyRosary' . holyRosary)
  , ("01060", Shrivelling' . shrivelling)
  , ("01061", Scrying' . scrying)
  , ("01062", ArcaneStudies' . arcaneStudies)
  , ("01063", ArcaneInitiate' . arcaneInitiate)
  , ("01070", BookOfShadows3' . bookOfShadows3)
  , ("01071", GrotesqueStatue4' . grotesqueStatue4)
  , ("01072", LeatherCoat' . leatherCoat)
  , ("01073", Scavenging' . scavenging)
  , ("01074", BaseballBat' . baseballBat)
  , ("01075", RabbitsFoot' . rabbitsFoot)
  , ("01076", StrayCat' . strayCat)
  , ("01077", DigDeep' . digDeep)
  , ("01086", Knife' . knife)
  , ("01087", Flashlight' . flashlight)
  , ("01117", LitaChantler' . litaChantler)
  , ("02006", ZoeysCross' . zoeysCross)
  , ("02010", JennysTwin45s' . jennysTwin45s)
  , ("02012", JimsTrumpet' . jimsTrumpet)
  , ("02014", Duke' . duke)
  , ("02147", Bandolier' . bandolier)
  , ("50001", PhysicalTraining2' . physicalTraining2)
  , ("50003", Hyperawareness2' . hyperawareness2)
  , ("50005", HardKnocks2' . hardKnocks2)
  , ("50007", ArcaneStudies2' . arcaneStudies2)
  , ("50009", DigDeep2' . digDeep2)
  , ("50010", RabbitsFoot3' . rabbitsFoot3)
  ]

slotsOf :: Asset -> [SlotType]
slotsOf = assetSlots . assetAttrs

isHealthDamageable :: Asset -> Bool
isHealthDamageable a = case assetHealth (assetAttrs a) of
  Nothing -> False
  Just n -> n > assetHealthDamage (assetAttrs a)

isSanityDamageable :: Asset -> Bool
isSanityDamageable a = case assetSanity (assetAttrs a) of
  Nothing -> False
  Just n -> n > assetSanityDamage (assetAttrs a)

assetAttrs :: Asset -> Attrs
assetAttrs = \case
  Rolands38Special' attrs -> coerce attrs
  DaisysToteBag' attrs -> coerce attrs
  TheNecronomicon' attrs -> coerce attrs
  HeirloomOfHyperborea' attrs -> coerce attrs
  WendysAmulet' attrs -> coerce attrs
  FortyFiveAutomatic' attrs -> coerce attrs
  PhysicalTraining' attrs -> coerce attrs
  BeatCop' attrs -> coerce attrs
  FirstAid' attrs -> coerce attrs
  Machete' attrs -> coerce attrs
  GuardDog' attrs -> coerce attrs
  PoliceBadge2' attrs -> coerce attrs
  BeatCop2' attrs -> coerce attrs
  Shotgun4' attrs -> coerce attrs
  MagnifyingGlass' attrs -> coerce attrs
  OldBookOfLore' attrs -> coerce attrs
  ResearchLibrarian' attrs -> coerce attrs
  DrMilanChristopher' attrs -> coerce attrs
  Hyperawareness' attrs -> coerce attrs
  MedicalTexts' attrs -> coerce attrs
  MagnifyingGlass1' attrs -> coerce attrs
  DiscOfItzamna2' attrs -> coerce attrs
  Encyclopedia2' attrs -> coerce attrs
  Switchblade' attrs -> coerce attrs
  Burglary' attrs -> coerce attrs
  Pickpocketing' attrs -> coerce attrs
  FortyOneDerringer' attrs -> coerce attrs
  LeoDeLuca' attrs -> coerce attrs
  HardKnocks' attrs -> coerce attrs
  LeoDeLuca1' attrs -> coerce attrs
  CatBurgler1' attrs -> coerce attrs
  ForbiddenKnowledge' attrs -> coerce attrs
  HolyRosary' attrs -> coerce attrs
  Shrivelling' attrs -> coerce attrs
  Scrying' attrs -> coerce attrs
  ArcaneStudies' attrs -> coerce attrs
  ArcaneInitiate' attrs -> coerce attrs
  BookOfShadows3' attrs -> coerce attrs
  LeatherCoat' attrs -> coerce attrs
  Scavenging' attrs -> coerce attrs
  BaseballBat' attrs -> coerce attrs
  RabbitsFoot' attrs -> coerce attrs
  StrayCat' attrs -> coerce attrs
  DigDeep' attrs -> coerce attrs
  Knife' attrs -> coerce attrs
  Flashlight' attrs -> coerce attrs
  LitaChantler' attrs -> coerce attrs
  ZoeysCross' attrs -> coerce attrs
  JennysTwin45s' attrs -> coerce attrs
  JimsTrumpet' attrs -> coerce attrs
  Duke' attrs -> coerce attrs
  Bandolier' attrs -> coerce attrs
  PhysicalTraining2' attrs -> coerce attrs
  Hyperawareness2' attrs -> coerce attrs
  HardKnocks2' attrs -> coerce attrs
  ArcaneStudies2' attrs -> coerce attrs
  GrotesqueStatue4' attrs -> coerce attrs
  DigDeep2' attrs -> coerce attrs
  RabbitsFoot3' attrs -> coerce attrs

module Arkham.Types.Investigator.Cards.DaisyWalkerParallel
  ( DaisyWalkerParallel(..)
  , daisyWalkerParallel
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Game.Helpers
import Arkham.Types.Investigator.Attrs
import Arkham.Types.InvestigatorId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Query
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Stats
import Arkham.Types.Target
import Arkham.Types.Token
import Arkham.Types.Trait
import Arkham.Types.Window

newtype DaisyWalkerParallel = DaisyWalkerParallel InvestigatorAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity)

daisyWalkerParallel :: DaisyWalkerParallel
daisyWalkerParallel = DaisyWalkerParallel
  $ baseAttrs "90001" "Daisy Walker" Seeker stats [Miskatonic]
 where
  stats = Stats
    { health = 5
    , sanity = 7
    , willpower = 1
    , intellect = 5
    , combat = 2
    , agility = 2
    }

instance HasCount AssetCount env (InvestigatorId, [Trait]) => HasModifiersFor env DaisyWalkerParallel where
  getModifiersFor source target@(InvestigatorTarget iid) (DaisyWalkerParallel attrs@InvestigatorAttrs {..})
    | iid == investigatorId
    = do
      tomeCount <- unAssetCount <$> getCount (investigatorId, [Tome])
      baseModifiers <- map modifierType <$> getModifiersFor source target attrs
      pure
        $ toModifiers attrs
        $ SkillModifier SkillWillpower tomeCount
        : SanityModifier tomeCount
        : baseModifiers
  getModifiersFor source target (DaisyWalkerParallel attrs) =
    getModifiersFor source target attrs

ability :: InvestigatorAttrs -> Ability
ability attrs = (mkAbility (toSource attrs) 1 (FastAbility Free))
  { abilityLimit = PlayerLimit PerGame 1
  }

instance HasTokenValue env DaisyWalkerParallel where
  getTokenValue (DaisyWalkerParallel attrs) iid ElderSign
    | iid == investigatorId attrs = pure
    $ TokenValue ElderSign (PositiveModifier 1)
  getTokenValue (DaisyWalkerParallel attrs) iid token =
    getTokenValue attrs iid token

instance InvestigatorRunner env => HasAbilities env DaisyWalkerParallel where
  getAbilities iid FastPlayerWindow (DaisyWalkerParallel attrs)
    | iid == investigatorId attrs = withBaseActions iid FastPlayerWindow attrs
    $ do
        hasTomes <- (> 0) . unAssetCount <$> getCount (iid, [Tome])
        pure [ ability attrs | hasTomes ]
  getAbilities i window (DaisyWalkerParallel attrs) = getAbilities i window attrs

instance InvestigatorRunner env => RunMessage env DaisyWalkerParallel where
  runMessage msg i@(DaisyWalkerParallel attrs@InvestigatorAttrs {..}) =
    case msg of
      UseCardAbility iid (InvestigatorSource iid') _ 1 _
        | investigatorId == iid' -> do
          tomeAssets <- filterM
            ((elem Tome <$>) . getSet)
            (setToList investigatorAssets)
          pairs' <-
            filter (notNull . snd)
              <$> traverse (\a -> (a, ) <$> getAbilities iid NonFast a) tomeAssets
          if null pairs'
            then pure i
            else i <$ push
              (chooseOneAtATime iid $ map
                (\(tome, actions) -> TargetLabel
                  (AssetTarget tome)
                  [Run [chooseOne iid $ map (UseAbility iid) actions]]
                )
                pairs'
              )
      UseCardAbility iid (TokenEffectSource ElderSign) _ 2 _
        | iid == investigatorId -> i
        <$ push (SearchDiscard iid (InvestigatorTarget iid) [Tome])
      ResolveToken _drawnToken ElderSign iid | iid == investigatorId ->
        i <$ push
          (chooseOne
            iid
            [ UseCardAbility
              iid
              (TokenEffectSource ElderSign)
              Nothing
              2
              NoPayment
            , Continue "Do not use Daisy's ability"
            ]
          )
      _ -> DaisyWalkerParallel <$> runMessage msg attrs

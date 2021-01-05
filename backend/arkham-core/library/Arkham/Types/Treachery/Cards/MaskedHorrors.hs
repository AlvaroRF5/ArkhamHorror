module Arkham.Types.Treachery.Cards.MaskedHorrors where

import Arkham.Import

import Arkham.Types.Game.Helpers
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype MaskedHorrors = MaskedHorrors Attrs
  deriving newtype (Show, ToJSON, FromJSON)

maskedHorrors :: TreacheryId -> a -> MaskedHorrors
maskedHorrors uuid _ = MaskedHorrors $ baseAttrs uuid "50031"

instance HasModifiersFor env MaskedHorrors where
  getModifiersFor = noModifiersFor

instance HasActions env MaskedHorrors where
  getActions i window (MaskedHorrors attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env MaskedHorrors where
  runMessage msg t@(MaskedHorrors attrs@Attrs {..}) = case msg of
    Revelation _ source | isSource attrs source -> do
      iids <- getInvestigatorIds
      targetInvestigators <- map fst . filter ((>= 2) . snd) <$> for
        iids
        (\iid -> do
          clueCount <- unClueCount <$> getCount iid
          pure (iid, clueCount)
        )
      t <$ if null targetInvestigators
        then unshiftMessages
          ([ InvestigatorAssignDamage iid source 0 2
           | iid <- targetInvestigators
           ]
          <> [Discard (TreacheryTarget treacheryId)]
          )
        else unshiftMessages
          [ PlaceDoomOnAgenda
          , AdvanceAgendaIfThresholdSatisfied
          , Discard (TreacheryTarget treacheryId)
          ]
    _ -> MaskedHorrors <$> runMessage msg attrs

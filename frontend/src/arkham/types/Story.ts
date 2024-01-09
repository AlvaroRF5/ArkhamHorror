import { JsonDecoder } from 'ts.data.json';
import { Placement, placementDecoder } from '@/arkham/types/Placement';
import { Target, targetDecoder } from '@/arkham/types/Target';

export type Story = {
  id: string
  cardId: string
  placement: Placement
  otherSide: Target | null
  flipped: boolean
}

export const storyDecoder = JsonDecoder.object<Story>({
  id: JsonDecoder.string,
  cardId: JsonDecoder.string,
  placement: placementDecoder,
  otherSide: JsonDecoder.nullable(targetDecoder),
  flipped: JsonDecoder.boolean
}, 'Story');

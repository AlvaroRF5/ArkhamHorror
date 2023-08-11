import { JsonDecoder } from 'ts.data.json';

export type Placement = { tag: "InThreatArea", contents: string } | { tag: "OtherPlacement", contents: string }

export const placementDecoder = JsonDecoder.oneOf<Placement>([
  JsonDecoder.object<Placement>({ tag: JsonDecoder.constant("InThreatArea"), contents: JsonDecoder.string }, 'InThreatArea'),
  JsonDecoder.object<Placement>({ tag: JsonDecoder.constant("OtherPlacement"), contents: JsonDecoder.string }, 'Placement', { contents: 'tag' }),
], 'Placement')

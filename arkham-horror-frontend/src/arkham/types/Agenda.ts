import { JsonDecoder } from 'ts.data.json';

export interface Agenda {
  tag: string;
  contents: AgendaContents;
}

export interface AgendaContents {
  doom: number;
  // doomThreshold: GameValue;
  id: string;
  name: string;
  sequence: string;
}

export const agendaContentsDecoder = JsonDecoder.object<AgendaContents>({
  doom: JsonDecoder.number,
  // doomThreshold: gameValueDecoder,
  id: JsonDecoder.string,
  name: JsonDecoder.string,
  sequence: JsonDecoder.string,
}, 'Attrs');

export const agendaDecoder = JsonDecoder.object<Agenda>({
  tag: JsonDecoder.string,
  contents: agendaContentsDecoder,
}, 'Agenda');

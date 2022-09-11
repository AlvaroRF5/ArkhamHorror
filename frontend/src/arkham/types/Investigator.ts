import { JsonDecoder } from 'ts.data.json';
import { Name, nameDecoder } from '@/arkham/types/Name';
import {
  Card,
  PlayerCardContents,
  playerCardContentsDecoder,
  cardDecoder,
} from '@/arkham/types/Card';

export interface ModifierType {
  tag: string
}

export const modifierTypeDecoder = JsonDecoder.object<ModifierType>(
  { tag: JsonDecoder.string}, 'ModifierType')

export interface Modifier {
  type: ModifierType
}

export const modifierDecoder = JsonDecoder.object<Modifier>(
  { type: modifierTypeDecoder}, 'Modifier')

type ClassSymbol = 'Guardian' | 'Seeker' | 'Rogue' | 'Mystic' | 'Survivor' | 'Neutral';

export const classSymbolDecoder = JsonDecoder.oneOf<ClassSymbol>([
  JsonDecoder.isExactly('Guardian'),
  JsonDecoder.isExactly('Seeker'),
  JsonDecoder.isExactly('Rogue'),
  JsonDecoder.isExactly('Mystic'),
  JsonDecoder.isExactly('Survivor'),
  JsonDecoder.isExactly('Neutral'),
], 'ClassSymbol');

interface AdditionalAction {
  tag: string
}

export const additionalActionDecoder = JsonDecoder.object<AdditionalAction>(
  { tag: JsonDecoder.string}, 'AdditionalAction')

export interface Investigator {
  deckSize?: number;
  connectedLocations: string[];
  modifiers?: Modifier[];
  name: Name;
  id: string;
  class: ClassSymbol;
  health: number;
  sanity: number;
  willpower: number;
  intellect: number;
  combat: number;
  agility: number;
  healthDamage: number;
  sanityDamage: number;
  assignedHealthDamage: number;
  assignedSanityDamage: number;
  clues: number;
  resources: number;
  location: string;
  remainingActions: number;
  endedTurn: boolean;
  engagedEnemies: string[];
  assets: string[];
  discard: PlayerCardContents[];
  hand: Card[];
  deck: PlayerCardContents[];
  treacheries: string[];
  defeated: boolean;
  resigned: boolean;
  additionalActions: AdditionalAction[];
  cardsUnderneath: Card[];
  foundCards: Record<string, Card[]>;
  xp: number;
  supplies: string[];
}

export const investigatorDecoder = JsonDecoder.object<Investigator>({
  name: nameDecoder,
  id: JsonDecoder.string,
  class: classSymbolDecoder,
  health: JsonDecoder.number,
  sanity: JsonDecoder.number,
  willpower: JsonDecoder.number,
  intellect: JsonDecoder.number,
  combat: JsonDecoder.number,
  agility: JsonDecoder.number,
  healthDamage: JsonDecoder.number,
  sanityDamage: JsonDecoder.number,
  assignedHealthDamage: JsonDecoder.number,
  assignedSanityDamage: JsonDecoder.number,
  clues: JsonDecoder.number,
  resources: JsonDecoder.number,
  location: JsonDecoder.string,
  remainingActions: JsonDecoder.number,
  endedTurn: JsonDecoder.boolean,
  engagedEnemies: JsonDecoder.array<string>(JsonDecoder.string, 'EnemyId[]'),
  assets: JsonDecoder.array<string>(JsonDecoder.string, 'AssetId[]'),
  // deck: Deck PlayerCard,
  discard: JsonDecoder.array<PlayerCardContents>(playerCardContentsDecoder, 'PlayerCardContents[]'),
  hand: JsonDecoder.array<Card>(cardDecoder, 'Card[]'),
  deck: JsonDecoder.array<PlayerCardContents>(playerCardContentsDecoder, 'PlayerCardContents[]'),
  // traits: HashSet Trait,
  treacheries: JsonDecoder.array<string>(JsonDecoder.string, 'TreacheryId[]'),
  defeated: JsonDecoder.boolean,
  resigned: JsonDecoder.boolean,
  additionalActions: JsonDecoder.array<AdditionalAction>(additionalActionDecoder, 'AdditionalAction'),
  cardsUnderneath: JsonDecoder.array<Card>(cardDecoder, 'CardUnderneath'),
  foundCards: JsonDecoder.dictionary<Card[]>(JsonDecoder.array(cardDecoder, 'Card[]'), 'Dict<string, Card[]>'),
  xp: JsonDecoder.number,
  supplies: JsonDecoder.array<string>(JsonDecoder.string, 'supplies'),
  deckSize: JsonDecoder.optional(JsonDecoder.number),
  connectedLocations: JsonDecoder.array<string>(JsonDecoder.string, 'LocationId[]'),
  modifiers: JsonDecoder.optional(JsonDecoder.array<Modifier>(modifierDecoder, 'Modifier[]')),
}, 'Investigator');

import { JsonDecoder } from 'ts.data.json';

export enum MessageType {
  RUN = 'Run',
  TAKE_RESOURCES = 'TakeResources',
  DRAW_CARDS = 'DrawCards',
  PLAY_CARD = 'PlayCard',
  INVESTIGATE = 'Investigate',
  END_TURN = 'ChooseEndTurn',
  START_SKILL_TEST = 'StartSkillTest',
  COMMIT_CARD = 'SkillTestCommitCard',
  UNCOMMIT_CARD = 'SkillTestUncommitCard',
  AFTER_DISCOVER_CLUES = 'AfterDiscoverClues',
  ADVANCE_ACT = 'AdvanceAct',
  MOVE = 'MoveAction',
  FIGHT_ENEMY = 'FightEnemy',
  EVADE_ENEMY = 'EvadeEnemy',
  ENEMY_DAMAGE = 'EnemyDamage',
  CONTINUE = 'Continue',
  INVESTIGATOR_DAMAGE = 'InvestigatorDamage',
  ASSET_DAMAGE = 'AssetDamage',
  ENEMY_ATTACK = 'EnemyAttack',
  ACTIVATE_ABILITY = 'ActivateCardAbilityAction',
  USE_CARD_ABILITY = 'UseCardAbility',
  SKILL_TEST_RESULTS = 'SkillTestApplyResults',
  DISCARD_ASSET = 'DiscardAsset',
  DISCARD_CARD = 'DiscardCard',
  ADD_TO_HAND_FROM_DECK = 'AddToHandFromDeck',
  BEGIN_SKILL_TEST_AFTER_FAST = 'BeginSkillTestAfterFast',
  BEGIN_SKILL_TEST = 'BeginSkillTest',
  SEARCH_TOP_OF_DECK = 'SearchTopOfDeck',
  ADD_FOCUSED_TO_HAND = 'AddFocusedToHand',
  ADD_FOCUSED_TO_TOP_OF_DECK = 'AddFocusedToTopOfDeck',
  ENGAGE_ENEMY = 'EngageEnemy',
  LABEL = 'Label',
}

export interface Message {
  tag: MessageType;
  label: string | null;
  contents: any; // eslint-disable-line
}

export const messageTypeDecoder = JsonDecoder.oneOf<MessageType>(
  [
    JsonDecoder.isExactly('Run').then(() => JsonDecoder.constant(MessageType.RUN)),
    JsonDecoder.isExactly('TakeResources').then(() => JsonDecoder.constant(MessageType.TAKE_RESOURCES)),
    JsonDecoder.isExactly('DrawCards').then(() => JsonDecoder.constant(MessageType.DRAW_CARDS)),
    JsonDecoder.isExactly('PlayCard').then(() => JsonDecoder.constant(MessageType.PLAY_CARD)),
    JsonDecoder.isExactly('Investigate').then(() => JsonDecoder.constant(MessageType.INVESTIGATE)),
    JsonDecoder.isExactly('ChooseEndTurn').then(() => JsonDecoder.constant(MessageType.END_TURN)),
    JsonDecoder.isExactly('StartSkillTest').then(() => JsonDecoder.constant(MessageType.START_SKILL_TEST)),
    JsonDecoder.isExactly('SkillTestCommitCard').then(() => JsonDecoder.constant(MessageType.COMMIT_CARD)),
    JsonDecoder.isExactly('SkillTestUncommitCard').then(() => JsonDecoder.constant(MessageType.UNCOMMIT_CARD)),
    JsonDecoder.isExactly('AfterDiscoverClues').then(() => JsonDecoder.constant(MessageType.AFTER_DISCOVER_CLUES)),
    JsonDecoder.isExactly('AdvanceAct').then(() => JsonDecoder.constant(MessageType.ADVANCE_ACT)),
    JsonDecoder.isExactly('MoveAction').then(() => JsonDecoder.constant(MessageType.MOVE)),
    JsonDecoder.isExactly('FightEnemy').then(() => JsonDecoder.constant(MessageType.FIGHT_ENEMY)),
    JsonDecoder.isExactly('EvadeEnemy').then(() => JsonDecoder.constant(MessageType.EVADE_ENEMY)),
    JsonDecoder.isExactly('EnemyDamage').then(() => JsonDecoder.constant(MessageType.ENEMY_DAMAGE)),
    JsonDecoder.isExactly('Continue').then(() => JsonDecoder.constant(MessageType.CONTINUE)),
    JsonDecoder.isExactly('InvestigatorDamage').then(() => JsonDecoder.constant(MessageType.INVESTIGATOR_DAMAGE)),
    JsonDecoder.isExactly('AssetDamage').then(() => JsonDecoder.constant(MessageType.ASSET_DAMAGE)),
    JsonDecoder.isExactly('EnemyAttack').then(() => JsonDecoder.constant(MessageType.ENEMY_ATTACK)),
    JsonDecoder.isExactly('ActivateCardAbilityAction').then(() => JsonDecoder.constant(MessageType.ACTIVATE_ABILITY)),
    JsonDecoder.isExactly('UseCardAbility').then(() => JsonDecoder.constant(MessageType.USE_CARD_ABILITY)),
    JsonDecoder.isExactly('SkillTestApplyResults').then(() => JsonDecoder.constant(MessageType.SKILL_TEST_RESULTS)),
    JsonDecoder.isExactly('DiscardAsset').then(() => JsonDecoder.constant(MessageType.DISCARD_ASSET)),
    JsonDecoder.isExactly('DiscardCard').then(() => JsonDecoder.constant(MessageType.DISCARD_CARD)),
    JsonDecoder.isExactly('AddToHandFromDeck').then(() => JsonDecoder.constant(MessageType.ADD_TO_HAND_FROM_DECK)),
    JsonDecoder.isExactly('BeginSkillTestAfterFast').then(() => JsonDecoder.constant(MessageType.BEGIN_SKILL_TEST_AFTER_FAST)),
    JsonDecoder.isExactly('BeginSkillTest').then(() => JsonDecoder.constant(MessageType.BEGIN_SKILL_TEST)),
    JsonDecoder.isExactly('SearchTopOfDeck').then(() => JsonDecoder.constant(MessageType.SEARCH_TOP_OF_DECK)),
    JsonDecoder.isExactly('AddFocusedToHand').then(() => JsonDecoder.constant(MessageType.ADD_FOCUSED_TO_HAND)),
    JsonDecoder.isExactly('AddFocusedToTopOfDeck').then(() => JsonDecoder.constant(MessageType.ADD_FOCUSED_TO_TOP_OF_DECK)),
    JsonDecoder.isExactly('EngageEnemy').then(() => JsonDecoder.constant(MessageType.ENGAGE_ENEMY)),
  ],
  'MessageType',
);

export const unlabeledMessageDecoder = JsonDecoder.object<Message>(
  {
    tag: messageTypeDecoder,
    label: JsonDecoder.constant(''),
    contents: JsonDecoder.succeed,
  },
  'Message',
);

export const labeledMessageDecoder = JsonDecoder.object<Message>(
  {
    tag: JsonDecoder.constant(MessageType.LABEL),
    label: JsonDecoder.string,
    contents: JsonDecoder.succeed,
  },
  'Message',
  {
    label: 'labelFor',
    contents: 'unlabel',
  },
);

export const messageDecoder = JsonDecoder.oneOf<Message>([
  unlabeledMessageDecoder,
  labeledMessageDecoder,
], 'Message');

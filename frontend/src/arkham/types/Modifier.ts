import { JsonDecoder } from 'ts.data.json';

export type ModifierType = BaseSkillOf | ActionSkillModifier | SkillModifier | UseEncounterDeck | CannotEnter | OtherModifier

export type BaseSkillOf = {
  tag: "BaseSkillOf"
  skillType: string
  value: number
}

export type ActionSkillModifier = {
  tag: "ActionSkillModifier"
  action: string
  skillType: string
  value: number
}

export type SkillModifier = {
  tag: "SkillModifier"
  skillType: string
  value: number
}

export type UseEncounterDeck = {
  tag: "UseEncounterDeck"
  contents: string
}

export type CannotEnter = {
  tag: "CannotEnter"
  contents: string
}

export type OtherModifier = {
  tag: "OtherModifier"
  contents: string
}


export type Modifier = {
  type: ModifierType;
}

const modifierTypeDecoder = JsonDecoder.oneOf<ModifierType>([
  JsonDecoder.object<BaseSkillOf>(
    {
      tag: JsonDecoder.isExactly('BaseSkillOf'),
      skillType: JsonDecoder.string,
      value: JsonDecoder.number
    }, 'BaseSkillOf'),
  JsonDecoder.object<UseEncounterDeck>(
    {
      tag: JsonDecoder.isExactly('UseEncounterDeck'),
      contents: JsonDecoder.string
    }, 'UseEncounterDeck'),
  JsonDecoder.object<CannotEnter>(
    {
      tag: JsonDecoder.isExactly('CannotEnter'),
      contents: JsonDecoder.string
    }, 'UseEncounterDeck'),
  JsonDecoder.object<SkillModifier>(
    {
      tag: JsonDecoder.isExactly('SkillModifier'),
      skillType: JsonDecoder.string,
      value: JsonDecoder.number
    }, 'SkillModifier'),
  JsonDecoder.object<ActionSkillModifier>(
    {
      tag: JsonDecoder.isExactly('ActionSkillModifier'),
      action: JsonDecoder.string,
      skillType: JsonDecoder.string,
      value: JsonDecoder.number
    }, 'ActionSkillModifier'),
  JsonDecoder.object<OtherModifier>({
    tag: JsonDecoder.constant('OtherModifier'),
    contents: JsonDecoder.string
  }, 'OtherModifier', { contents: 'tag'}),
], 'ModifierType');

export const modifierDecoder = JsonDecoder.object<Modifier>({
  type: modifierTypeDecoder
}, 'Modifier')

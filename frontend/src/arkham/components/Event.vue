<script lang="ts" setup>
import { computed, ComputedRef } from 'vue';
import { Game } from '@/arkham/types/Game';
import { Card } from '@/arkham/types/Card';
import * as ArkhamGame from '@/arkham/types/Game';
import { AbilityLabel, AbilityMessage, Message, MessageType } from '@/arkham/types/Message';
import { imgsrc } from '@/arkham/helpers';
import PoolItem from '@/arkham/components/PoolItem.vue';
import AbilityButton from '@/arkham/components/AbilityButton.vue'
import Token from '@/arkham/components/Token.vue';
import * as Arkham from '@/arkham/types/Event';

export interface Props {
  game: Game
  event: Arkham.Event
  playerId: string
  attached?: boolean
}

const props = withDefaults(defineProps<Props>(), { attached: false })

const emits = defineEmits<{
  choose: [value: number]
  showCards: [e: Event, cards: ComputedRef<Card[]>, title: string, isDiscards: boolean]
}>()

const id = computed(() => props.event.id)
const hasPool = computed(() => {
  const { doom, sealedChaosTokens } = props.event
  return doom > 0 || sealedChaosTokens.length > 0
})

const cardCode = computed(() => props.event.cardCode)
const image = computed(() => {
  return imgsrc(`cards/${cardCode.value.replace('c', '')}.jpg`)
})
const choices = computed(() => ArkhamGame.choices(props.game, props.playerId))

function canInteract(c: Message): boolean {
  if (c.tag === MessageType.TARGET_LABEL) {
    return c.target.contents === id.value || c.target.contents === props.event.cardId
  }
  return false
}

const cardAction = computed(() => choices.value.findIndex(canInteract))

function isAbility(v: Message): v is AbilityLabel {
  if (v.tag !== MessageType.ABILITY_LABEL) {
    return false
  }

  const { source } = v.ability;

  if (source.sourceTag === 'ProxySource') {
    if("contents" in source.source) {
      return source.source.contents === id.value
    }
  } else if (source.tag === 'EventSource') {
    return source.contents === id.value
  }

  return false
}

const abilities = computed(() => {
  return choices.value
    .reduce<AbilityMessage[]>((acc, v, i) => {
      if (isAbility(v)) {
        return [...acc, { contents: v, displayAsAction: false, index: i }];
      }

      return acc;
    }, []);
})

const cardsUnderneath = computed(() => props.event.cardsUnderneath)
const cardsUnderneathLabel = computed(() => `Underneath (${cardsUnderneath.value.length})`)

const showCardsUnderneath = (e: Event) => emits('showCards', e, cardsUnderneath, "Cards Underneath", false)

const choose = (index: number) => emits('choose', index)
</script>

<template>
  <div class="event" :class="{ attached }">
    <img
      :src="image"
      :class="{ 'event--can-interact': cardAction !== -1 }"
      class="card event"
      @click="$emit('choose', cardAction)"
    />
    <div v-if="hasPool" class="pool">
      <PoolItem v-if="event.doom > 0" type="doom" :amount="event.doom" />
      <Token
        v-for="(sealedToken, index) in event.sealedChaosTokens"
        :key="index"
        :token="sealedToken"
        :playerId="playerId"
        :game="game"
        @choose="choose"
      />
    </div>
    <AbilityButton
      v-for="ability in abilities"
      :key="ability.index"
      :ability="ability.contents"
      :data-image="image"
      @click="$emit('choose', ability.index)"
      />

    <button v-if="cardsUnderneath.length > 0" class="view-discard-button" @click="showCardsUnderneath">{{cardsUnderneathLabel}}</button>
  </div>
</template>

<style lang="scss" scoped>
.card {
  width: $card-width;
  max-width: $card-width;
  border-radius: 5px;
}

.event {
  display: flex;
  flex-direction: column;
  position: relative;
}

.event--can-interact {
  border: 2px solid $select;
  cursor:pointer;
}

.button{
  margin-top: 2px;
  border: 0;
  color: #fff;
  border-radius: 4px;
  border: 1px solid #ff00ff;
}

:deep(.token) {
  width: 40px;
}

.pool {
  position: absolute;
  top: 50%;
  align-items: center;
  display: flex;
  align-self: flex-start;
  align-items: flex-end;
  * {
    transform: scale(0.6);
  }
  z-index: 1;
  pointer-events: none;
}

.attached .card {
  object-fit: cover;
  object-position: left bottom;
  height: $card-width*0.6;
}
</style>

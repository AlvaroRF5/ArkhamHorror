<script lang="ts" setup>
import { computed, ref, inject } from 'vue'
import type { Game } from '@/arkham/types/Game';
import { fetchDecks } from '@/arkham/api'
import { imgsrc } from '@/arkham/helpers'
import * as Arkham from '@/arkham/types/Deck'
import type { Investigator } from '@/arkham/types/Investigator'

const decks = ref<Arkham.Deck[]>([])
const ready = ref(false)
const deckId = ref<string | null>(null)

const props = defineProps<{
  game: Game
  playerId: string
}>()

const chooseDeck = inject<(deckId: string) => Promise<void>>('chooseDeck')

const error = computed(() => {
  if(!deckId.value) {
    return null
  }

  const deck = decks.value.find((d) => d.id === deckId.value)
  if (!deck) {
    return null
  }

  const alreadyTaken = Object.values(props.game.investigators).some((i) => {
    return i.id === deck.list.investigator_code
  })

  if (alreadyTaken) {
    return 'This investigator is already taken'
  }

  return null
})

const disabled = computed(() => {
  if(!deckId.value) {
    return true
  }

  return error.value !== null
})

const investigators = computed(() => props.game.investigators)
const chosenPlayerCount = computed(() => {
  return Object.values(investigators.value).length
})
const empties = computed(() => {
  return Array(props.game.playerCount - chosenPlayerCount.value).fill(0)
})

fetchDecks().then((result) => {
  decks.value = result;
  ready.value = true;
})

async function choose() {
  if (deckId.value && error.value === null) {
    if (chooseDeck) {
      await chooseDeck(deckId.value)
    }
  }
}

function portraitImage(investigator: Investigator) {
  return imgsrc(`portraits/${investigator.cardCode.replace('c', '')}.jpg`)
}

const needsReply = computed(() => {
  const question = props.game.question[props.playerId]
  return question !== null && question !== undefined
})
</script>

<template>
  <div class="container">
    <div class="investigators">
      <h2>Chosen Players</h2>
      <div class="portraits">
        <img
          v-for="investigator in investigators"
          :key="investigator.id"
          :src="portraitImage(investigator)"
          class="portrait"
        />
        <div class="portrait portrait-empty"
          v-for="(item,index) in empties"
          :key="chosenPlayerCount - index">
          <img
            :src="imgsrc('slots/ally.png')"
          />
        </div>
      </div>
    </div>
    <form id="choose-deck" @submit.prevent="choose" v-if="needsReply">
      <p>Choose a Deck</p>
      <select v-model="deckId">
        <option disabled :value="null">-- Select a Deck--</option>
        <option v-for="deck in decks" :key="deck.id" :value="deck.id">{{deck.name}}</option>
      </select>
      <p class="error" v-if="error">{{error}}</p>
      <button type="submit" :disabled="disabled">Choose</button>
    </form>
  </div>
</template>


<style lang="scss" scoped>
.investigators {
  box-sizing: border-box;
  width: 100%;
  color: #FFF;
  background-color: #15192C;
  padding: 10px;
  border-radius: 3px;
  max-width: 800px;
  margin-inline: auto;
  margin-top: 20px;

  h2 {
    margin: 0;
    padding: 0;
    text-transform: uppercase;
    color: white;
  }
}

.portraits {
  --gap: 10px;
  --columns: 4;
  display: flex;
  gap: var(--gap);
}

#choose-deck {
  box-sizing: border-box;
  width: 100%;
  color: #FFF;
  background-color: #15192C;
  padding: 10px;
  border-radius: 3px;
  button {
    outline: 0;
    padding: 15px;
    background: #6E8640;
    text-transform: uppercase;
    color: white;
    border: 0;
    width: 100%;
    &:hover {
      background: darken(#6E8640, 7%);
    }
  }
  button[disabled] {
    background: #999;
    cursor: not-allowed;
    &:hover {
      background: #999;
    }
  }
  input[type=text] {
    outline: 0;
    border: 1px solid #000;
    padding: 15px;
    background: #F2F2F2;
    width: 100%;
    box-sizing: border-box;
    margin-bottom: 10px;
  }
  select {
    outline: 0;
    border: 1px solid #000;
    padding: 15px;
    background: #F2F2F2;
    width: 100%;
    box-sizing: border-box;
    margin-bottom: 10px;
    background-image:
      linear-gradient(45deg, transparent 50%, gray 50%),
      linear-gradient(135deg, gray 50%, transparent 50%),
      linear-gradient(to right, #ccc, #ccc);
    background-position:
      calc(100% - 25px) calc(1.3em + 2px),
      calc(100% - 20px) calc(1.3em + 2px),
      calc(100% - 3.5em) 0.5em;
    background-size:
      5px 5px,
      5px 5px,
      1px 2.5em;
    background-repeat: no-repeat;
  }
  a {
    color: #365488;
    font-weight: bolder;
  }
  p {
    margin: 0;
    padding: 0;
    text-transform: uppercase;
  }
}

h2 {
  color: #656A84;
  margin-left: 10px;
  text-transform: uppercase;
}

input[type=radio] {
  display: none;
  /* margin: 10px; */
}

input[type=radio] + label {
  display:inline-block;
  padding: 4px 12px;
  background-color: desaturate(#6E8640, 30%);
  &:hover {
    background-color: desaturate(#6E8640, 20%);
  }
  border-color: #ddd;
}

input[type=radio]:checked + label {
  background: #6E8640;
}

input[type=checkbox] {
  display: none;
  /* margin: 10px; */
}

input[type=checkbox] + label {
  display:inline-block;
  padding: 4px 12px;
  background-color: desaturate(#6E8640, 30%);
  &:hover {
    background-color: desaturate(#6E8640, 20%);
  }

  border-color: #ddd;
}

input[type=checkbox]:checked + label {
  background: #6E8640;
}

header {
  display: flex;
  align-items: center;
  justify-items: center;
  align-content: center;
  justify-content: center;
}

select::-ms-expand {
  display: none;
}

select {
  appearance: none;
  -moz-appearance: none;
  -webkit-appearance: none;
}

.container {
  background: #1C1D2E;
  width: 100%;
  max-width: unset;
  height: 100%;
  margin: 0;
}

form {
  max-width: 800px;
  margin-inline: auto;
  margin-top: 20px;
}

#choose-deck {
  p.error {
    color: white;
    background-color: darkred;
    padding: 10px;
    text-align: center;
    margin-bottom: 10px;
    display: block;
  }
}

.portrait {
  width: calc((100% / var(--columns)) - var(--gap) + (var(--gap) / var(--columns)));
  border-radius: 5px;
}

.portrait-empty {
  aspect-ratio: 63/97;
  background: rgba(100, 100, 100, 0.5);
  display: flex;
  align-items: center;
  align-content: center;
  justify-content: center;
  justify-items: center;
  img {
    width: 80%;
  }
}
</style>
